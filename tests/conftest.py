def pytest_addoption(parser):
    parser.addoption("--dir", nargs="+", help="Directory to test", required=False)