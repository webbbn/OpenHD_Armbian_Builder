# OpenHD_Armbian_Builder
Scripts for building and OpenHD image using Armbian

## Kernel configuration changes

- Enable CONFIG_EXPERT

~~~
yes "" | make oldconfig
~~~

- Enable CONFIG_NET_FOU=m
- Enable CONFIG_NET_FOU_IP_TUNNELS=y
- Enable CONFIG_CFG80211_CERTIFICATION_ONUS=y
- Disable CONFIG_CFG80211_REQUIRE_SIGNED_REGDB is not set
- Disable CONFIG_CFG80211_CRDA_SUPPORT is not set

~~~
yes "" | make oldconfig
~~~

## Kernels used for each board

| Board | Kernel |
|---|---|
| Nanopi Neo2 | sunxi64-next |
| Nanopi Neo Plus2 | sunxi64-next |
| Nanopi Neo4 | rk3399-default |
| Nanopi Fire3 | s5p6818-next |
| Nanopi Neo Core2 | sunxi64-next |
| Nanopi Duo2 | sun8i-next |
