if [ -f /tmp/pwn ]; then
    echo "Exploit successful"
    rm -rf /tmp/pwn
    exit 0
else
    echo "Exploit failed"
    exit 1
fi