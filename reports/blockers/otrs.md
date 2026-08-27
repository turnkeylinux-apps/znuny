# PRODUCT-BLOCKED

> **Status semantics:** Review approval of this blocker dossier does **not**
> constitute `SHIP` for the OTRS v19 migration and must not be counted as a
> shipped migration in aggregate reporting. It confirms only that the blocker
> evidence and handoff are complete. The migration remains `PRODUCT-BLOCKED`.

Official evidence: OTRS maintains a current commercial product and security process, but its current hardware and software requirements list Debian 11 and 12 rather than Debian 13; its installation and upgrade documentation routes both operations through the OTRS Customer Solutions Team, while OTRS officially ended security updates for OTRS 6 and ((OTRS)) Community Edition 6 in March 2020.
Debian route: Debian 13's `otrs2` 6.5.15-2 binary comes from source package `znuny`, is described by Debian as “Open Ticket Request System Znuny,” and names the Znuny project as its homepage; installing it would replace OTRS with a distinct fork.
Official upstream route: The maintained OTRS channel has no supported Debian 13 target or public, integrity-verifiable installation feed available to this appliance build; the official documentation says installation and upgrades are performed through the Customer Solutions Team and OTRS Portal.
Fixture investigation: Web login, queue and ticket create/read, database persistence, daemon and scheduled jobs, and local mail can all be exercised with local fixtures once an eligible OTRS artifact exists, but the existing `/otrs/index.pl` and `otrs.Console.pl` fixture targets Znuny 6.5 and cannot establish the identity or update contract of current OTRS.
Security consequences: Reusing OTRS Community Edition 6 would ship a product whose vendor security updates ended in 2020; using Debian's maintained Znuny package would silently change products; using current OTRS outside its published operating-system and customer delivery boundary would lack a vendor-supported Trixie provenance and maintenance contract.
Update consequences: Debian APT can update Znuny but not current OTRS, and the documented current OTRS upgrade route requires Customer Solutions access rather than exposing a reproducible appliance update channel; therefore no eligible installed OTRS release can pass the required non-destructive update check.
Decision required: Resume only after OTRS publishes or supplies an integrity-verifiable release and update channel supported on Debian 13 with redistribution authority, or after the product owner explicitly approves renaming and substituting the appliance with Znuny, another maintained product, or retirement.

## Disposition

- Outcome: `PRODUCT-BLOCKED`
- Evidence date: 2026-08-26 UTC
- Appliance source reviewed: `05de1f479d28124037d546c255a1f9da4007c5b5`
- Product-fix loops: 0 of 6
- v19 migration claim: none
- Runtime claim: none

OTRS remains actively maintained as a commercial service-management product.
That keeps this result distinct from retirement. The blocker is that no current
OTRS release meets the approved Trixie source, provenance, and updater
contract. The similarly named Debian package is Znuny, which the v18 README
already acknowledges as a fork and a future rename candidate. A Znuny port may
be technically feasible, but accepting that fork under the `otrs` product name
requires a separate product decision.

This is the migration program's domain `PRODUCT-BLOCKED` outcome. It does not
represent a Genie lifecycle impasse, a v19 appliance build, or a passing
runtime result.

## Product identity and support boundary

### Maintained OTRS product

The official [OTRS documentation landing page][otrs-docs] identifies its
contents as the documentation for the latest OTRS release. The current
[hardware and software requirements][otrs-requirements] include a dependency
row for the `2025.7.1 – 2025.x.y` release line and list these supported Linux
operating systems:

- CentOS Stream 9;
- Debian 11 and 12;
- Gentoo;
- Red Hat Enterprise Linux 8 and 9; and
- Ubuntu 20.04, 22.04, and 24.04.

Debian 13 is absent from that vendor support boundary. TurnKey v19 is based on
Debian 13, so installing current OTRS into the required Trixie root would be an
unsupported operating-system combination.

The official OTRS [installation page][otrs-installation] says that OTRS is
installed by its Customer Solutions Team and directs users to support or the
OTRS Portal. The official [update guide][otrs-updating] likewise says that OTRS
is upgraded by that team. It documents migration mechanics for entitled
installations, but it does not publish a generally accessible release artifact
or package feed that a clean TurnKey build can authenticate, acquire, and
exercise as an updater.

OTRS also retains a vendor security process. Its official FAQ identifies
`security@otrs.org` as the vulnerability-reporting route and states that OTRS
and ((OTRS)) Community Edition are different products. This evidence supports
`PRODUCT-BLOCKED`, rather than treating the maintained commercial OTRS product
as retired.

### Community Edition end of security support

OTRS Group's official [Community Edition announcement][otrs-ce-eol] says that
OTRS 6 and ((OTRS)) Community Edition 6 reached end of life at the end of March
2020 and receive no further security updates. That release therefore cannot
serve as the maintained upstream fallback for a new v19 appliance.

The same announcement discontinued the Community Edition. A historical OTRS
6 source archive may remain downloadable, but archive availability is not a
supported stable channel and does not provide the required security or update
contract.

## Attempted Debian route

The official [Debian Trixie package page][debian-otrs2] exposes one package
with the historical binary name `otrs2`, version `6.5.15-2`. Its source archive
is `znuny_6.5.15-2`, its description is “Open Ticket Request System Znuny,” and
the signed Debian source control file reports:

```text
Source: znuny
Version: 6.5.15-2
Homepage: https://github.com/znuny/Znuny
```

Debian archive signatures and APT would provide a sound integrity and updater
boundary for that package, but only for Znuny. The package does not contain the
current OTRS product.

The v18 appliance source makes this distinction explicit. Its README says
that OTRS upstream went closed source, that the appliance installs the Znuny
fork, and that the appliance is intended to be renamed to Znuny. Its build
configuration installs Debian's `otrs2` package and exercises Znuny's legacy
paths. Carrying those choices into v19 would preserve a known substitution,
not migrate OTRS.

| Route | Observed result | Contract consequence |
| --- | --- | --- |
| Debian Trixie `otrs2` | Signed Debian package sourced from Znuny 6.5.15-2. | Eligible provenance for Znuny, but the product identity changes. |
| OTRS 6 / Community Edition 6 | Officially reached end of security updates in March 2020. | Ineligible for a new security-maintained appliance. |
| Current commercial OTRS | Maintained release line, but Debian 13 is outside the published OS list and delivery is customer-mediated. | No supported, reproducible Trixie source or updater boundary. |
| TurnKey migration relabeled as Znuny | Technically plausible using Debian APT. | Requires explicit product rename or substitution authority. |

## Official-upstream and update-path investigation

The maintained OTRS route fails two independent completion boundaries:

1. **Compatibility:** the official requirements list Debian 11 and 12, not
   Debian 13. A successful build probe would not convert Trixie into a
   vendor-supported OTRS platform.
2. **Reproducibility and updates:** official installation and upgrades are
   customer-mediated. No public release feed was found that a clean appliance
   build can pin, authenticate, redistribute, and later query through a
   non-destructive update check.

A private customer artifact would not resolve those boundaries by itself. The
appliance would also need documented redistribution permission, stable
provenance and integrity metadata, vendor confirmation of Debian 13 support,
and an update credential or feed that survives deployment to end users.

The Debian route has the inverse property: it offers excellent signed package
provenance and updates, but for Znuny. Mixing OTRS branding and acceptance
claims with Znuny packages would conceal the exact product decision that the
migration contract requires reviewers and users to see.

## Test-fixture investigation

The OTRS-specific behaviors in the group goal do not require unsafe external
services. With a supported OTRS artifact and license boundary, a disposable
runtime could:

1. finish firstboot with throwaway credentials;
2. log into the official agent interface at `/agent`;
3. create and read a queue and a ticket through supported OTRS interfaces;
4. verify the ticket record in the configured database;
5. verify the OTRS daemon and scheduled worker state;
6. inject an RFC 822 message through a loopback mail fixture and read the
   resulting ticket; and
7. invoke a customer-authorized non-destructive update query before service
   restart checks.

The local mail fixture would cover the appliance side without a paid external
mail provider. Database and background-job checks are likewise local. No
identity-defining behavior is inherently untestable.

The preserved migration candidate instead logged into `/otrs/index.pl`, ran
`/usr/share/otrs/bin/otrs.Console.pl`, and reported the package source as Znuny
6.5 LTS. Those checks may be useful for a separately approved Znuny appliance,
but they cannot prove current OTRS login, ticket identity, jobs, mail behavior,
or its maintained update channel. The candidate was therefore reverted and no
configured-root or exact runtime was queued for this disposition.

## Security consequences

- OTRS Community Edition 6 has had no vendor security-update commitment since
  March 2020. Functional success would not restore maintenance.
- Debian's package receives distribution updates as Znuny. Treating those
  updates as OTRS updates would misstate both the vendor and security channel.
- Installing current OTRS on Debian 13 would cross the vendor's published OS
  boundary, leaving TurnKey to own unapproved compatibility and security
  behavior.
- Acquiring a customer-only artifact without a documented redistribution and
  update contract would prevent reproducible builds and dependable downstream
  patch delivery.

## Update consequences

- APT can report and apply `otrs2` updates only for the Znuny source package.
  That is a valid Znuny updater, not an OTRS updater.
- Community Edition 6 has no eligible vendor security target to update to.
- The current OTRS guide sends installation and major-version upgrades through
  the Customer Solutions Team. The migration has no public feed or credentials
  with which to prove an installed-version query, authenticated candidate, dry
  run, or data-preserving update.
- An appliance-specific downloader around an unavailable or contract-restricted
  artifact would invent a TurnKey update channel and cannot satisfy the
  official-upstream rule.

## Exact decision needed to resume

Resume this lane after one of these product-level decisions or upstream state
changes is recorded:

1. OTRS supplies an on-premises release supported on Debian 13, an
   integrity-verifiable acquisition and update channel suitable for deployed
   appliances, and written redistribution authority; or
2. the product owner explicitly approves Znuny as the replacement, renames and
   rebrands the appliance accordingly, and authorizes its migration and user
   compatibility policy as a separate product; or
3. the product owner selects another maintained replacement or retires the
   historical OTRS appliance.

Until one of those decisions is made, the accurate terminal domain outcome is
`PRODUCT-BLOCKED`. No product-fix loop was consumed because no eligible OTRS
source exists to build or diagnose.

## Reproduction commands

These bounded commands were run from the dedicated OTRS worktree on
2026-08-26. They use only official OTRS and Debian sources:

```bash
curl -LfsS https://academy.otrs.com/doc/update/requirements/ \
  | grep -E 'Debian 11 and 12|Debian 13|2025\.7\.1'

curl -LfsS https://academy.otrs.com/doc/update/installation/ \
  | grep -F 'installed by the <em>Customer Solutions Team</em>'

curl -LfsS https://academy.otrs.com/doc/update/updating/ \
  | grep -F 'upgraded by the <em>Customer Solutions Team</em>'

curl -LfsS \
  https://corporate.otrs.com/otrs-group-discontinues-its-community-edition-until-further-notice/ \
  | perl -0777 -pe 's/<[^>]*>/ /g; s/&#[0-9]+;/ /g; s/\s+/ /g' \
  | grep -E 'no further security updates for OTRS 6|end of March 2020'

curl -LfsS https://otrs.com/hu/szolgaltatasok/gyik/ \
  | perl -0777 -pe 's/<[^>]*>/ /g; s/&#[0-9]+;/ /g; s/\s+/ /g' \
  | grep -E 'security@otrs.org|OTRS is different from.*Community Edition'

curl -LfsS https://packages.debian.org/en/trixie/otrs2 \
  | grep -E 'Open Ticket Request System Znuny|znuny_6\.5\.15-2\.dsc'

curl -LfsS \
  https://deb.debian.org/debian/pool/non-free/z/znuny/znuny_6.5.15-2.dsc \
  | sed -n '/^Source:/p;/^Version:/p;/^Homepage:/p'

git show master:README.rst \
  | grep -E 'installs the Znuny|renamed to "Znuny"'
git show master:conf.d/main | grep 'apt-get install --assume-yes otrs2'
```

Observed facts:

```text
Current OTRS release documentation: 2025.7.1 through 2025.x.y
Published OTRS Debian targets: Debian 11 and Debian 12
Published OTRS Debian 13 target: none
Official install route: OTRS Customer Solutions Team / OTRS Portal
Official upgrade route: OTRS Customer Solutions Team / OTRS Portal
Community Edition 6 security end: March 2020
Debian Trixie binary: otrs2 6.5.15-2
Debian Trixie source identity: znuny 6.5.15-2
Existing v18 application identity: Znuny fork under historical OTRS naming
Exact build and runtime: not run for dossier-only outcome
```

[otrs-docs]: https://academy.otrs.com/doc/
[otrs-requirements]: https://academy.otrs.com/doc/update/requirements/
[otrs-installation]: https://academy.otrs.com/doc/update/installation/
[otrs-updating]: https://academy.otrs.com/doc/update/updating/
[otrs-ce-eol]: https://corporate.otrs.com/otrs-group-discontinues-its-community-edition-until-further-notice/
[otrs-faq]: https://otrs.com/hu/szolgaltatasok/gyik/
[debian-otrs2]: https://packages.debian.org/en/trixie/otrs2
