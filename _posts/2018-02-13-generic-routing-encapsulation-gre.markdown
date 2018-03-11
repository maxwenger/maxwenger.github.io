---
layout: post
title: "Generic Routing Encapsulation (GRE)"
date: 2018-02-13
categories:
  - Networking
description: 
image: /assets/img/2018-02-13-generic-routing-encapsulation-gre/cover.png
image-sm: /assets/img/2018-02-13-generic-routing-encapsulation-gre/cover-sm.png
---

GRE is one of many Virtual Private Network (VPN) technologies. VPNs act like a conduit that runs between two (or more... foreshadowing!) routers where traffic can flow through as if the remote router is directly connected, even when its not. Where VPNs really show their hand is when we implement a layer of security on top of our GRE tunnel. This will protect all data flowing between sites.

# How it Works

From the routers perspective, a GRE tunnel is just like any other interface: it has an IP address, it can be enabled or disabled, a routing protocol can be enabled on it, and anything else a normal interface can do. The only difference: there is no physical "tunnel" cable. It is a virtual link between the two devices.
The magic of the GRE tunnel is in the GRE header. It takes the original packet, with the original IP header, and adds a GRE header and a new IP header. The IP header is sent to the destination interface of the other side of the tunnel. This "protects"/hides the GRE payload from any routing. Only the new ip header is routed.

# How it Looks
![R1 and R2, both connected over a WAN link (192.168.1.0/24); R1 and R2 connected by tunn0 (10.0.0.0/30).](/assets/img/2018-02-13-generic-routing-encapsulation-gre/how-it-looks.png)
