// Fresh original vector-resource experiment. No retail container is input.
using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Security.Cryptography;
using WolvenKit.Common.Model;
using WolvenKit.CR2W;
using WolvenKit.CR2W.Types;

internal static class CmfOriginalResourceHost
{
	static string Hash(byte[] b) { using(var h = SHA256.Create()) return BitConverter.ToString(h.ComputeHash(b)).Replace("-", "").ToLowerInvariant(); }
	static string Safe(string p) {
		p = Path.GetFullPath(p);
		for (string n=p; n!=null; n=Path.GetDirectoryName(n))
			if ((File.Exists(n)||Directory.Exists(n)) && (File.GetAttributes(n)&FileAttributes.ReparsePoint)!=0) throw new IOException("reparse path");
		return p;
	}
	static int Main(string[] args) {
		try {
			if(args.Length != 4) throw new ArgumentException("MOVIE SHA OUTPUT_RED RESOURCE_NAME");
			// Copied dependencies remain beside the previously qualified host.
			string root = Safe(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "toolchains", "s02b1", "cr2w"));
			AppDomain.CurrentDomain.AssemblyResolve += delegate(object sender, ResolveEventArgs e) {
				string n=new AssemblyName(e.Name).Name;
				if(n.IndexOfAny(new char[]{'/', '\\', ':'})>=0) return null;
				string p=Safe(Path.Combine(root,n+".dll"));
				return File.Exists(p)?Assembly.LoadFrom(p):null;
			};
			return Run(args);
		} catch(Exception e) { Console.Error.WriteLine(e); return 1; }
	}
	[MethodImpl(MethodImplOptions.NoInlining)]
	static int Run(string[] a) {
		string output=Safe(a[2]), cwd=Safe(Environment.CurrentDirectory);
		string boundary=Safe(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,".."));
		if(!boundary.EndsWith("\\build\\panel-runs",StringComparison.OrdinalIgnoreCase) || !cwd.StartsWith(boundary.TrimEnd('\\')+"\\",StringComparison.OrdinalIgnoreCase) || !output.StartsWith(cwd.TrimEnd('\\')+"\\",StringComparison.OrdinalIgnoreCase) || File.Exists(output)) throw new IOException("new contained output required");
		if(a[3]!="icon.swf" && a[3]!="grid.swf") throw new ArgumentException("fixture name");
		byte[] movie=File.ReadAllBytes(Safe(a[0]));
		if(movie.Length<16 || movie.Length>1024*1024 || Hash(movie)!=a[1] || movie[0]!='F' || movie[1]!='W' || movie[2]!='S' || movie[3]!=10 || BitConverter.ToUInt32(movie,4)!=movie.Length) throw new InvalidDataException("movie pin/framing");
		var file=new CR2WFile();
		// Source-inspected private struct has no public version setter.
		var header=file.GetFileHeader(); header.version=164; header.numChunks=1;
		typeof(CR2WFile).GetField("m_fileheader",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(file,header);
		var chunk=file.CreateChunk("CSwfResource",0); chunk.REDObjectFlags=8192;
		var swf=(CSwfResource)chunk.data; swf.SetREDFlags(8192);
		swf.LinkageName=new CString(file,swf,"linkageName"); swf.LinkageName.SetValue(a[3]);
		// Like the pinned cooked resource, omit optional authoring Header. SWF
		// framing is authoritative; no guessed duplicate geometry is serialized.
		swf.SwfResource=new CByteArray(file,swf,"SwfResource"); swf.SwfResource.SetValue(movie);
		swf.Unk1=new CUInt32(file,swf,"Unk1"); swf.Unk1.SetValue((uint)0);
		byte[] emitted=null; file.Write(ref emitted);
		var read=new CR2WFile();
		if(read.Read(emitted)!=EFileReadErrorCodes.NoError || read.GetFileHeader().version!=164 || read.chunks.Count!=1 || read.imports.Count!=0 || read.buffers.Count!=0 || read.embedded.Count!=0 || read.UnknownTypes.Count!=0) throw new InvalidDataException("topology readback");
		var check=(CSwfResource)read.chunks[0].data;
		if(!check.SwfResource.Bytes.SequenceEqual(movie) || check.LinkageName.val!=a[3] || check.Unk1.val!=0 || (check.Textures!=null && check.Textures.Count!=0) || (check.Fonts!=null && check.Fonts.Count!=0)) throw new InvalidDataException("resource readback");
		byte[] roundtrip=null; read.Write(ref roundtrip);
		if(!emitted.SequenceEqual(roundtrip)) throw new InvalidDataException("roundtrip bytes");
		using(var f=new FileStream(output,FileMode.CreateNew)) f.Write(emitted,0,emitted.Length);
		foreach(var assembly in AppDomain.CurrentDomain.GetAssemblies()) if(!assembly.IsDynamic) Console.WriteLine("ASSEMBLY "+assembly.Location+" "+Hash(File.ReadAllBytes(assembly.Location)));
		Console.WriteLine("CMF_ORIGINAL_RESOURCE "+Hash(emitted)); return 0;
	}
}
