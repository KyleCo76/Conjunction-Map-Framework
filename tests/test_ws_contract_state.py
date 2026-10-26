"""Opt-in shared class fields for nested source-derived WS execution."""
import unittest
from ws_contract_runner import bind, run


class AskRunnerBoundaryTests(unittest.TestCase):
    def test_nested_source_method_sees_live_scalar_writes(self):
        source="""function Outer() : bool { catching = true; result = Inner(); catching = false; return result; }
        function Inner() : bool { return catching; }"""
        env={"catching":False,"__ws_live_state__":("catching",)}
        env["Inner"]=bind(source,"Inner",env,())
        self.assertTrue(run(source,"Outer",env))
        self.assertFalse(env["catching"])

    def test_nested_source_write_reaches_caller_without_argument_or_local_leaks(self):
        source="""function Outer() : int { Inner(99); return value; }
        function Inner(argument : int) { value = argument; }
        function Shadow(value : int) : int { Inner(7); return value; }
        function Local() : int { var value : int; value = 11; Inner(8); return value; }"""
        env={"value":1,"__ws_live_state__":("value",)}
        env["Inner"]=bind(source,"Inner",env,("argument",))
        self.assertEqual(run(source,"Outer",env),99)
        self.assertEqual(env["value"],99)
        shadow=bind(source,"Shadow",env,("value",))
        self.assertEqual(shadow(3),3)
        self.assertEqual(env["value"],7)
        self.assertEqual(run(source,"Local",env),11)
        self.assertEqual(env["value"],8)
        self.assertNotIn("argument",env)

    def test_string_literal_whitespace_and_keywords_are_preserved(self):
        source='function Text() : string { return "true  false\t(int)"; }'
        self.assertEqual(run(source,"Text",{}),"true  false\t(int)")

    def test_literal_byte_shapes_without_python_escape_decoding(self):
        for text in ("plain space", "two  spaces", "\t", r"\t", r"\n", "__ws_literal_1__"):
            with self.subTest(text=repr(text)):
                source='function Text() : string { return "'+text+'"; }'
                self.assertEqual(run(source,"Text",{}),text)

    def test_ws_quote_closes_after_single_trailing_backslash(self):
        expected="tail"+chr(92)
        source='function Text() : string { return "'+expected+'"; }'
        self.assertEqual(run(source,"Text",{}),expected)

    def test_trailing_backslash_before_another_quoted_literal(self):
        expected="tail"+chr(92)
        source='function Text() : string { return "'+expected+'" + "next"; }'
        self.assertEqual(run(source,"Text",{}),expected+"next")

    def test_trailing_backslash_before_comment_preserves_url_literal(self):
        expected="img://tail"+chr(92)
        source='function Text() : string { return "'+expected+'"; // comment "quoted" text\n }'
        self.assertEqual(run(source,"Text",{}),expected)
