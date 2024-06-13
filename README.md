<h1 align="center">S5 Deploy</h1>
<div align="center">
 <strong>
   Simple CLI to Deploy Static Websites to S5
 </strong>
</div>

![S5 CLI Demo](static/demo.cast.svg)

## Install

**Single line install**:

```bash
bash <(curl -s https://raw.githubusercontent.com/s5-dev/s5_deploy/main/install.sh)
```

**Compile Yourself**:
[Install dart](https://dart.dev/get-dart#install) first.

```
git clone https://github.com/s5-dev/s5_deploy.git
cd s5_deploy
dart compile exe bin/s5_deploy.dart
sudo mv ./bin/s5_deploy.exe /usr/local/bin/s5_deploy
```

## Usage

```
s5_deploy ./file/or/folder
-V, --version    Gets the version number of package
-h, --help       Print help dialoge.
    --reset      Resets local node BE CAREFUL
    --static     Skips resolver deploy
-n, --node       Which S5 node to deploy to
                 (defaults to "https://s5.ninja")
-S, --seed       Set seed to recover DNS Link Entry
-d, --dataKey    Set the dataKey of the upload, defaults to target directory
```

### Guide to Resolver Links

For more details on the internals, read the [S5 Docs](https://docs.sfive.net/concepts/registry.html).

Resolver Links are a S5 [CID](https://docs.sfive.net/concepts/content-addressed-data.html) that point to a mutable registry entry as opposed to a static dataset. This means they can be updated in the future if you wish to update the contents without changing the link. This can be especially useful when used in conjunction with [DNSLink](https://dnslink.org/) to deploy static websites to traditional domains.

These Resolver Links are generated with 2 components, the user seed and the corresponding dataKey. In this implementation the dataKey is directly derived from the absolute path of the directory. So as long as the path and seed don't change, s5_deploy will automatically update the registry entry without any configuration. The ability to pass a dataKey and seed exist as well if you want to change the data path or machine.

## Acknowledgement

This work is supported by a [Sia Foundation](https://sia.tech/) grant
