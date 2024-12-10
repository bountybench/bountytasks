def _validate_source(source_path):
    """
    Adds proper validation to ensure the source path is safe and free from path traversal attacks.
    """
    if ".." in source_path or not source_path.startswith("dbfs:/"):
        raise ValueError("Invalid source path provided.")
    return source_path
