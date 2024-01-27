# Waybar/i3bar GL.iNet Mudi status

*this required the v4 firmware*

This is a small bash script compatible with the waybar/i3bar data format to display cell and battery information from the [GL.iNet Mudi](https://www.gl-inet.com/products/gl-e750/) in your tiling window manager status bar. Ideal for knowing why your website does't load in a tunnel.

This script is hacked toghether in a train while procastinating serious work so expect bash crimes, PRs welcome.

## How to use (waybar)

Edit the `status.sh` script to your needs, don't forget to add the credentials

Add to your configuration:

```json
"custom/gli": {
    "format": "{}",
    "exec": "~/.path-to-script/status.sh",
    "interval": 4,
}
```

Add to your style.css:

```css
#custom-gli {
   background-color: #eb4d4b;
   padding: 0 10px;
}
```

**Note:** make sure `curl` and `jq` are installed.