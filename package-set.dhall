let upstream = https://github.com/aviate-labs/package-set/releases/download/v0.1.0/package-set.dhall sha256:c3c8109cb725af1f6c2f879b8383e347d76c95b1cc743a88fe88b82c198fa06a
let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }

let additions = [
  { name = "auth"
  , repo = "https://github.com/aviate-labs/auth.mo"
  , version = "v0.1.0"
  , dependencies = [ "base" ]
  }
] : List Package

in  upstream # additions
