# Verifying releases

The [installer](installation.md) and [`camy update`](reference/camy_update.md)
already verify every download over TLS against a SHA-256 checksum before
anything is installed. This page is for going further: checking a release's
signed manifest, reading its SBOM, and knowing exactly what is inside a
release tarball.

## What a release publishes

| File | What it is | Where |
| --- | --- | --- |
| `camy_<version>_<os>_<arch>.tar.gz` | One platform's tarball: the `camy` binary at its root, `README.md`, and, when the release ships them, `completions/` and `manpages/` directories. | Both |
| `camy_<version>_<os>_<arch>.tar.gz.sbom.cdx.json` | A CycloneDX SBOM for that tarball. | Both |
| `SHA256SUMS-<version>` | That release's own checksum manifest, under a version-scoped name so it is never overwritten. The signatures cover this file. | Both |
| `SHA256SUMS-<version>.sig` | Detached cosign signature for that manifest. | Both |
| `SHA256SUMS-<version>.pem` | The certificate that signature was made with. | Both |
| `SHA256SUMS-<version>.minisig` | minisign signature for that manifest. | Both |
| `SHA256SUMS` | A merged, cumulative checksum index spanning every published version. This is what the installer and `camy update` check downloads against. | Channel only |
| `VERSION` | The current version as a plain-text string — what the installer and `camy update` read to find the latest release. | Channel only |

The two checksum names serve different purposes. `SHA256SUMS` is convenient:
one file, works with any release, grows with every version. Because its bytes
change with every release, it is never the file a signature covers.

`SHA256SUMS-<version>` is the exact set of bytes a release's signature was
computed over, scoped to that release alone, which is what makes it
verifiable with `cosign` below.

## Where to get them

- The **GitHub Release** for that tag, at
  <https://github.com/trycamy/cli/releases>, as downloadable assets.
- The **release channel**, `https://dl.camy.sh/stable/`, which serves those
  same files plus the merged `SHA256SUMS` and `VERSION`.

The GitHub Release is created by this repository's
[release-mirror workflow](../.github/workflows/release-mirror.yml): it
downloads a version from the channel, runs exactly the checks described
below, and uploads the same files. The channel is the origin of every asset.

Pick whichever is easier to script against. The tarballs and SBOMs are
byte-identical in both.

## Verifying a checksum

Download a tarball and `SHA256SUMS` from either location, then confirm the
tarball's hash matches the line for its filename:

```bash
shasum -a 256 -c <(grep camy_1.0.0_darwin_arm64.tar.gz SHA256SUMS)
```

On Linux, `sha256sum` is the equivalent:

```bash
sha256sum -c <(grep camy_1.0.0_darwin_arm64.tar.gz SHA256SUMS)
```

A mismatch, or no matching line at all, means don't run the binary.
Re-download from a trusted network, or verify the signed manifest below to
rule out a compromised mirror.

## Verifying the signature

A checksum proves a file was not corrupted in transit. It does not prove who
built it. For that, verify the version-scoped manifest with
[cosign](https://docs.sigstore.dev/cosign/):

```bash
cosign verify-blob \
  --certificate SHA256SUMS-1.0.0.pem \
  --signature SHA256SUMS-1.0.0.sig \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github\.com/CamyAI/camy-cli/\.github/workflows/release\.yml@refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' \
  SHA256SUMS-1.0.0
```

Download the manifest, its signature, and its certificate from the release
channel first — there they are `SHA256SUMS-1.0.0`, `SHA256SUMS-1.0.0.sig`,
and `SHA256SUMS-1.0.0.pem`.

Verification is keyless: it checks the signature against GitHub Actions' OIDC
issuer and against an identity you pin yourself. Pin the identity, never read
it out of the certificate you are checking — that proves nothing more than
that some GitHub Actions workflow signed the file.

The certificate names the workflow that signed the manifest. camy is built
and signed by the release workflow of the CLI's source repository, not by
this one, so the identity to pin is that workflow's path; the regexp above
matches it for any release tag. To see the identity a certificate actually
carries:

```bash
openssl x509 -in SHA256SUMS-1.0.0.pem -noout -text | grep -A1 'Subject Alternative Name'
```

A successful verification confirms that `SHA256SUMS-1.0.0` was signed by a
workflow matching that identity, through GitHub Actions' OIDC issuer, using a
short-lived certificate issued at signing time. There is no long-lived
private key to leak.

Once the manifest itself is trusted, check your tarball's hash against it:

```bash
grep camy_1.0.0_darwin_arm64.tar.gz SHA256SUMS-1.0.0
shasum -a 256 camy_1.0.0_darwin_arm64.tar.gz
```

Compare the two hashes by hand, or point `shasum -c` at the grep'd line as
shown earlier.

A minisign signature, `SHA256SUMS-1.0.0.minisig`, is also published, for
readers who prefer a single pinned key to a certificate chain. The public
key is:

```text
RWT7bpmBcMfiVQvo6BbIeVDh7f9B8WbapvOEBzs7TxhSkLsjlySfxXG6
```

Record it somewhere you trust; it changes only if the signing key is
rotated, which this document will say. Verify with
[minisign](https://jedisct1.github.io/minisign/) (the `minisign`
package on Homebrew and most distributions):

```bash
minisign -Vm SHA256SUMS-1.0.0 -x SHA256SUMS-1.0.0.minisig \
  -P RWT7bpmBcMfiVQvo6BbIeVDh7f9B8WbapvOEBzs7TxhSkLsjlySfxXG6
```

A good result prints `Signature and comment signature verified` and a
trusted comment carrying the signing timestamp and the manifest's name.
Either signature alone is sufficient; they are produced by the same
release run over the same bytes.

### Why the merged `SHA256SUMS` is not signed

It was never the input to a signature. `SHA256SUMS` grows with every release:
the file that exists today has different bytes than the one that existed when
version 1.0.0 shipped, so signing it once would mean nothing for a later
download.

The signature covers the manifest for a single release, published as
`SHA256SUMS-<version>`, whose contents are fixed forever at that version's
release. Cryptographic assurance, rather than TLS and a checksum, needs the
version-scoped file.

## What the installer and `camy update` check

Both fetch over TLS and check the downloaded tarball's SHA-256 against the
merged `SHA256SUMS` before installing or swapping anything into place.
Neither runs the cosign or minisign verification above.

That trust model is TLS plus a checksum, the same level of assurance package
managers typically provide. For the signature-based guarantee, run the
`cosign verify-blob` steps yourself before installing.

`camy update` also refuses to honor `CAMY_DL_BASE`, an override for which
host it downloads from, on any released binary. Only an unstamped development
build reads that variable, and only when it is a well-formed `https://` URL.
A poisoned shell profile cannot redirect `camy update` at another host.

The installer script is different. It honors `CAMY_DL_BASE` unconditionally,
because pointing it at a mirror is how the script itself is retargeted, and an
`http://` override also turns off its HTTPS pin, leaving only the checksum.
Check the environment before piping the installer to a shell.

## Reading the SBOM

Each tarball ships a matching CycloneDX SBOM listing the Go modules built into
that binary. It is a standard [CycloneDX](https://cyclonedx.org/) JSON
document — read it with any CycloneDX-aware tool, or with `jq`:

```bash
jq -r '.components[] | "\(.name) \(.version)"' camy_1.0.0_darwin_arm64.tar.gz.sbom.cdx.json
```

Use it to check whether a specific dependency or version is present in a given
release, or to feed your own software-composition scanning.

## Reproducible builds

Release builds are compiled with `-trimpath` and `CGO_ENABLED=0`, and the
binary's timestamp inside the tarball is taken from the tagged commit rather
than the build time. Two builds of the same commit for the same
`GOOS`/`GOARCH` produce the same `camy` binary. The CLI's source is not
published, so this describes how releases are built rather than a check you
can run today.

## See also

- [Installation](installation.md) — the one-line installer, Homebrew, and
  manual downloads
- [Troubleshooting](troubleshooting.md) — [`camy doctor`](reference/camy_doctor.md),
  update failures, and the diagnosis card when the binary's directory isn't
  writable
- [Exit codes](exit-codes.md) — exit 1, the runtime code `camy update` uses
  when a checksum doesn't match and it won't install
