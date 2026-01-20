# Network Access Troubleshooting

If you can't access the Flask application from another computer on the same network, check the following:

## 1. Verify the Application is Running

On the Debian server, check if the Flask app is running:

```bash
# Check if Python process is running
ps aux | grep python

# Or check if port 5000 is listening
sudo netstat -tlnp | grep 5000
# or
sudo ss -tlnp | grep 5000
```

## 2. Check Firewall (UFW)

Debian/Ubuntu often uses UFW firewall. Check and allow port 5000:

```bash
# Check firewall status
sudo ufw status

# Allow port 5000
sudo ufw allow 5000/tcp

# If firewall was inactive, enable it
sudo ufw enable
```

## 3. Check iptables (if UFW not used)

```bash
# Check iptables rules
sudo iptables -L -n

# Allow port 5000
sudo iptables -A INPUT -p tcp --dport 5000 -j ACCEPT

# Save iptables rules (Debian)
sudo apt install iptables-persistent
sudo netfilter-persistent save
```

## 4. Verify IP Address

Make sure you're using the correct IP address:

```bash
# On the Debian server, check IP address
ip addr show
# or
hostname -I
```

The IP should be something like `192.168.x.x` (not `127.0.0.1` or `localhost`).

## 5. Test Locally First

On the Debian server, test if the app responds locally:

```bash
curl http://localhost:5000
# or
curl http://127.0.0.1:5000
```

If this works but network access doesn't, it's a firewall/network issue.

## 6. Test from Server to Client

From the Debian server, try to ping your computer:

```bash
ping 192.168.16.XXX  # Replace with your computer's IP
```

## 7. Check Flask is Binding to 0.0.0.0

Verify in `app.py` that it says:

```python
flask_app.run(host="0.0.0.0", port=5000, debug=True)
```

**NOT** `host="127.0.0.1"` (which only allows localhost access).

## 8. Quick Fix: Restart with Explicit Host

Stop the current Flask app and restart it explicitly:

```bash
# Stop the app (Ctrl+C or kill process)
# Then run:
python app.py
```

Or if using Gunicorn:

```bash
gunicorn -w 4 -b 0.0.0.0:5000 'app:create_app()'
```

## 9. Check Systemd Service (if running as service)

If running as a systemd service, check the service configuration:

```bash
sudo systemctl status rfq-tracker
sudo journalctl -u rfq-tracker -f
```

Make sure the service file uses `0.0.0.0` not `127.0.0.1`.

## 10. Alternative: Use Different Port

If port 5000 is blocked, try a different port:

```bash
# Edit app.py, change port to 8080
flask_app.run(host="0.0.0.0", port=8080, debug=True)

# Then allow that port
sudo ufw allow 8080/tcp
```

Then access via `http://192.168.16.103:8080`

## Most Common Solution

Usually it's the firewall. Run these commands on your Debian server:

```bash
sudo ufw allow 5000/tcp
sudo ufw reload
```

Then try accessing from your computer again.
