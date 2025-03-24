# Publishing a Cairo package as library

**This document explains how to organize and publish Cairo package that can be imported and used as dependency by other developers**

## Getting started
First, you need a Cairo package. You can create one with:
```sh
scarb new project_name
```

For more details, check out [this documentation](https://github.com/KaizeNodeLabs/starkiro/blob/main/README.md).

## Preparing your package
### Defining the library target
In your Scarb.toml manifest, add a `[lib]` section. This tells Scarb that your package exports a reusable library.

### Adding  package metadata
In the `[package]` section, you can include basic fields that provide useful information for other developers. Although these fields are optional, it is recommended that you add:
- `description`: A short explanation of your package's purpose
- `documentation`: A link to the package’s documentation
- `repository`: A URL to the GitHub repository where the source code is hosted
- `license`: The license under which the package is distributed
- `homepage`: A link to the project's website or landing page

For a complete list of available metadata fields, please refer to the [scarb documentation](https://docs.swmansion.com/scarb/docs/reference/manifest.html).

## Publishing your package

### Official Scarb registry (recommended)

The official [Scarb registry](https://scarbs.xyz/) is a central hub where developers can list, discover, and retrieve packages. Publishing your package here makes it easy for others to use your library.

To publish your package:

1. **Generate an API Token**
Log into the registry dashboard and create a token with the `publish` scope.

2. **Run the Publish Command**
```sh
SCARB_REGISTRY_AUTH_TOKEN=scrb_mytoken scarb publish
```
The publish command automatically packages and verifies your package. Then it will publish your package to the official scarbs.xyz registry. **Once the package is published, it's impossible to unpublish it.**

### Alternative Option
If your package is hosted on GitHub, you can directly add it as a dependency in your project without publishing to the official registry. For example:

```sh
scarb add your_package --git https://github.com/username/your_package.git
```

This method pulls the package directly from the GitHub repository. However, using the official registry is recommended for better discoverability and integration.

## Resources
- [Scarb Documentation](https://docs.swmansion.com/scarb/docs/guides/dependencies.html)
- [Scarb Package Registery](https://scarbs.xyz/)
- [Cairo Library Example](https://github.com/KaizeNodeLabs/starkiro/tree/main/examples/cairo/scripts/regex)