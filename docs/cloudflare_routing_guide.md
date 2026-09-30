# Exposing Services via Cloudflare Tunnels (Through the RPi)

Because your Raspberry Pi is running `cloudflared` (the Cloudflare Tunnel agent) and is connected to both your local network and Tailscale, it can act as a bridge. This means Cloudflare can securely route public web traffic to your Raspberry Pi, and the Pi can forward that traffic to **any other machine** on your Tailscale mesh or local network (like your Mac Mini or Acer Nitro).

Let's say your Mac Mini has a Tailscale IP of `100.x.x.x` (or a local IP of `10.x.x.x`) and is running a web app on port `8080`. 

Here is how you expose that Mac Mini service to the world at `app.leazirondi.com.br` using the Raspberry Pi's tunnel.

## Method 1: The Cloudflare Zero Trust Dashboard (Recommended)

Since we set up the `cloudflared` container in NixOS using a `TUNNEL_TOKEN`, your tunnel is remotely managed. This is the easiest method because **you do not need to change anything in NixOS or reboot the Pi!**

1. Go to the [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/).
2. Navigate to **Networks** -> **Tunnels**.
3. Click on your active tunnel (the one running on the Pi) and click **Configure**.
4. Go to the **Public Hostname** tab and click **Add a public hostname**.
5. **Public Hostname settings:**
   * **Subdomain:** `app` (or whatever you want)
   * **Domain:** Choose your domain from the dropdown (e.g., `leazirondi.com.br`).
6. **Service settings:**
   * **Type:** `HTTP` (or HTTPS if your Mac Mini service uses SSL natively).
   * **URL:** Enter the IP and port of your Mac Mini (e.g., `100.x.x.x:8080` if using Tailscale, or `10.x.x.x:8080` if using local LAN).
7. Click **Save hostname**.

Within seconds, Cloudflare will start routing traffic for `app.leazirondi.com.br` down the tunnel to your Raspberry Pi, and the Pi will forward it via Tailscale/LAN to the Mac Mini!

---

## Method 2: Local Configuration File (If not using Remote Management)

If you decide later that you want to define your routing rules purely locally on the Pi (instead of the Cloudflare website), you would need to change how the container runs in NixOS to mount a `config.yml` file.

*You don't need to do this if you used Method 1, but here is how it works just in case:*

1. Create a config file at `/var/lib/cloudflared/config.yml` on the Pi:
```yaml
tunnel: <YOUR_TUNNEL_UUID>
credentials-file: /var/lib/cloudflared/credentials.json

ingress:
  # Route to the Mac Mini
  - hostname: app.leazirondi.com.br
    service: http://10.x.x.x:8080
  
  # Catch-all rule (Required)
  - service: http_status:404
```

2. If you ever switch to this method, you would update your `rpi-services.nix` container definition to point to this file:
```nix
      # Cloudflare Tunnel Container
      cloudflared = {
        image = "cloudflare/cloudflared:latest";
        cmd = [ "tunnel" "--config" "/etc/cloudflared/config.yml" "run" ];
        volumes = [ 
            "/var/lib/cloudflared:/etc/cloudflared" 
        ];
        extraOptions = [ "--network=host" ];
        autoStart = true;
      };
```

## Security Note for the Mac Mini
When exposing services this way, the Mac Mini will see the traffic as coming from the Raspberry Pi's IP address (because the Pi is acting as a proxy). Make sure the firewall on your Mac Mini allows incoming connections on port `8080` from the Pi's Tailscale or local IP.
