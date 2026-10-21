// CMF-owned bounded caller. The copied corrected library owns serialization.
using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Security.Cryptography;
using WolvenKit.Common.Model;
using WolvenKit.CR2W;
using WolvenKit.CR2W.Types;

internal static class CmfCr2wHost
{
	static string assemblyRoot;
	static string Hash(byte[] data)
	{
		using (var h = SHA256.Create()) return BitConverter.ToString(h.ComputeHash(data)).Replace("-", "").ToLowerInvariant();
	}
	static string Safe(string path)
	{
		path = Path.GetFullPath(path);
		for (string p = path; p != null; p = Path.GetDirectoryName(p))
			if ((File.Exists(p) || Directory.Exists(p)) && (File.GetAttributes(p) & FileAttributes.ReparsePoint) != 0)
				throw new IOException("Reparse path refused: " + p);
		return path;
	}
	static void Save(string path, byte[] data)
	{
		using (var f = new FileStream(Safe(path), FileMode.CreateNew, FileAccess.Write, FileShare.None)) f.Write(data, 0, data.Length);
	}
	static int Main(string[] args)
	{
		try
		{
			if (args.Length != 5) throw new ArgumentException("INPUT INPUT_SHA OUTPUT_DIR MOVIE_OR_DASH MOVIE_SHA_OR_DASH");
			assemblyRoot = Safe(AppDomain.CurrentDomain.BaseDirectory);
			AppDomain.CurrentDomain.AssemblyResolve += delegate(object sender, ResolveEventArgs e)
			{
				string name = new AssemblyName(e.Name).Name;
				if (name.IndexOfAny(new char[] {'/', '\\', ':'}) >= 0) return null;
				string path = Safe(Path.Combine(assemblyRoot, name + ".dll"));
				return File.Exists(path) ? Assembly.LoadFrom(path) : null;
			};
			return Run(args);
		}
		catch (Exception error) { Console.Error.WriteLine(error); return 1; }
	}
	static CR2WFile Read(byte[] data)
	{
		var file = new CR2WFile();
		if (file.Read(data) != EFileReadErrorCodes.NoError) throw new InvalidDataException("Read failed");
		if (file.chunks.Count != 6 || file.imports.Count != 0 || file.buffers.Count != 0 || file.embedded.Count != 0 || file.UnknownTypes.Count != 0 ||
			(file.AdditionalCr2WFileBytes != null && file.AdditionalCr2WFileBytes.Length != 0) ||
			file.chunks.Any(c => c.unknownBytes != null && c.unknownBytes.Bytes != null && c.unknownBytes.Bytes.Length != 0))
			throw new InvalidDataException("Unsupported topology/unknown data");
		if (file.chunks[0].REDType != "CSwfResource" || file.chunks.Skip(1).Any(c => c.REDType != "CSwfTexture"))
			throw new InvalidDataException("Unsupported export types");
		return file;
	}
	[MethodImpl(MethodImplOptions.NoInlining)]
	static int Run(string[] args)
	{
		string input = Safe(args[0]), output = Safe(args[2]);
		// Host build lives at <repo>/build/toolchains/s02b1/cr2w/.
		string root = Safe(Path.Combine(assemblyRoot, "..", "..", "..", "panel-runs"));
		if (!output.StartsWith(root.TrimEnd('\\') + "\\", StringComparison.OrdinalIgnoreCase) || Directory.Exists(output) || File.Exists(output))
			throw new IOException("Output must be a new contained panel-runs directory");
		byte[] original = File.ReadAllBytes(input);
		if (original.Length > 16 * 1024 * 1024 || Hash(original) != args[1]) throw new InvalidDataException("Input pin/size mismatch");
		var file = Read(original);
		var swf = (CSwfResource)file.chunks[0].data;
		byte[] expected = swf.SwfResource.Bytes;
		Console.WriteLine("INPUT " + Hash(original) + " movie=" + Hash(expected) + " fonts=" + (swf.Fonts == null ? 0 : swf.Fonts.Count) + " textures=" + (swf.Textures == null ? 0 : swf.Textures.Count) + " Unk1=" + swf.Unk1.val);
		if (args[3] != "-")
		{
			expected = File.ReadAllBytes(Safe(args[3]));
			if (expected.Length > 16 * 1024 * 1024 || Hash(expected) != args[4]) throw new InvalidDataException("Movie pin/size mismatch");
			swf.SwfResource.SetValue(expected);
		}
		byte[] emitted = null;
		file.Write(ref emitted);
		var reread = Read(emitted);
		if (!((CSwfResource)reread.chunks[0].data).SwfResource.Bytes.SequenceEqual(expected)) throw new InvalidDataException("Movie readback differs");
		Directory.CreateDirectory(output);
		Save(Path.Combine(output, "panel.redswf"), emitted);
		Save(Path.Combine(output, "movie.gfx"), expected);
		foreach (var a in AppDomain.CurrentDomain.GetAssemblies())
			if (!a.IsDynamic) Console.WriteLine("ASSEMBLY " + a.FullName + " | " + a.Location + " | " + Hash(File.ReadAllBytes(a.Location)));
		Console.WriteLine("HOST_EMITTED " + Hash(emitted));
		return 0;
	}
}
