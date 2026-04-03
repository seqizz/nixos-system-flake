{ config, ... }:
{
  home.sessionVariables = {
    GOPATH = "~/devel/go";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    MOZ_USE_XINPUT2 = 1;
    # Poetry
    PYTHON_KEYRING_BACKEND = "keyring.backends.null.Keyring";
  };
}
