# Switching ISP to PPPoE w/ IPv4 & IPv6

Finally escaping the clutches of Rogers and switching to E-BOX (Bell Subsidiary 😔). The ONLY thing I'll miss from Rogers is the static IPv4 address they provide. So I'll need to re-configure my Wireguard server, but that'll be for another guide.

# Resources

- [OPNSense PPPoE Setup](https://docs.opnsense.org/manual/how-tos/pppoe_isp_setup.html)
- [Blog about IPv6 & E-BOX](https://ogdenslake.ca/2021/02/12/pfsense-and-ipv6-ebox-ca/)
- [E-BOX FAQ PPPoE Credentials](https://www.ebox.ca/en/quebec/residential/faq/find-your-ppoe-username-and-password/)

# Pre-requisites

Just grab your PPPoE credentials from your [E-BOX Customer Zone](https://client.ebox.ca/) and note down the VLAN ID (In this case it's **40**)
# How To

## PPPoE Setup

This is actually extremely easy. Just follow the OPNsense guide exactly. There's nothing specific you need to set in regards to EBOX **other than the vlan tag 40**

After you plug in the cable from the ONT to your OPNsense box, you should have an internet connection with an IPv4 address.

## Setting up IPv6 Support

**NOTE**: This is just to get an IPv6 address. I still haven't setup IPv6 on my LAN side permanently other than for testing.

The blogpost above has all the information, but the guide is for pfSense. I'll show you where the settings are in OPNSense. We'll only be doing the first few paragraphs of the guide.

1. Go to the interface setup you created for PPPoE under(In my case I named it EBOX_PPPoE) under **Interfaces -> [EBOX_PPPoE]**
2. Change IPv6 Configuration Type to: **DHCPv6**
3. Under **DHCPv6 client configuration** change the following
    - Prefix delegation size: 56
    - Request prefix only: Checked
    - Send prefix hint: Checked
4. Reboot your opnsense box (maybe you dont need to do this) and you should recieve an IPv6 address.

# E-BOX Thoughts

I've been using EBOX for about 2 weeks now, and it's been great so far. My OPNsense has an Intel G4600 and has no issue running a symmetric 1 gig link.

I know about the issue of EBOX routing all traffic through Montreal, and doing so results in a RTT in OPNsense around 12ms from Toronto. This is still lower than Rogers. I've seen no issues in online games. CS2 & Overwatch is 10ms lower than Rogers at around 30ms. TFT is around 5ms lower at around 25-30ms. Wish I got a bigger improvement, but as long as it's not worse I'm happy. 

I've noticed however, the IPv4 address they give shows a proper location of Toronto, but the IPv6 address is Montreal. I haven't done any further testing on this.

The IPv4 address they give isn't static, but the IPv6 one is static.

