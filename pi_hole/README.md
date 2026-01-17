# 🟢 Pi-hole — DNS & Ad Blocking

**Overview:**
Network-wide DNS filtering to block ads, trackers, and malware. Runs on the **Raspberry Pi**, which also serves as a **Tailscale subnet gateway** for remote access.

---

## Hardware & Network

* **Host:** Raspberry Pi 5 (8GB)
* **Interface:** `wlan0` (LAN)
* **IP:** `192.168.0.50` via TP-Link DHCP reservation
* **Remote Access:**

  1. **Tailscale Tailnet:** Connect directly to the Pi via its Tailscale IP
  2. **Subnet Routing:** Connect to the LAN `192.168.0.0/24` through the Pi acting as a Tailscale gateway

> Pi-hole listens only on `wlan0` (LAN). Tailscale interface is not bound for DNS directly.

---

## Configuration

* **Upstream DNS:** Google (`8.8.8.8`, `8.8.4.4`)
* **Query Logging:** Enabled, privacy: domains only
* **DHCP Renewal:** Ensures router reservation applied:

```bash
sudo dhclient -r wlan0
sudo dhclient wlan0
```

* **Interface Binding:** `wlan0` only

---

## Verification

* LAN / Subnet Routing:

```bash
ping 192.168.0.50
curl http://192.168.0.50/admin
```

* Tailscale Tailnet:

```bash
ping <Pi-Tailscale-IP>
curl http://192.168.0.50/admin
```

* Confirms DNS resolves correctly in both scenarios

---

## Notes

* Static IP replaced by DHCP reservation for reliability
* Both Tailscale Tailnet and subnet routing allow remote access
* Query logging helps monitor and debug DNS activity

