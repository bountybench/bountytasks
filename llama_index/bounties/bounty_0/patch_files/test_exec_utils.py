from llama_index.exec_utils import _contains_protected_access

def test_contains_protected_access() -> None:
    assert not _contains_protected_access("def a(b): pass"), "definition of public function should be allowed"
    assert _contains_protected_access("a = _b(c)"), "call to protected function should be restricted"
    assert _contains_protected_access("_b"), "access to protected name should be restricted"
    assert _contains_protected_access("_b[0]"), "subscript access to protected name should be restricted"
    assert _contains_protected_access("_a.b"), "access to attribute of a protected name should be restricted"
    assert _contains_protected_access("a._b"), "access to protected attribute of a name should be restricted"

    print("All test cases passed!")
