{ config, ... }:
{
  home.sessionVariables = {
    GOPATH = "~/devel/go";
    MOZ_USE_XINPUT2 = 1;
    # Poetry
    PYTHON_KEYRING_BACKEND = "keyring.backends.null.Keyring";
  };
}
