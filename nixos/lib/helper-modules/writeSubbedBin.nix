{pkgs}: {
  # Wrap scripts into programs
  writeSubbedBin = args: let
    name = args.name;
    src = args.src;
    substitutions = builtins.removeAttrs args ["name" "src"];
  in
    pkgs.runCommand name {} ''
      mkdir -p $out/bin
      substitute ${src} $out/bin/${name} \
        ${builtins.concatStringsSep " "
        (pkgs.lib.mapAttrsToList (k: v: "--replace '@${k}@' '${v}'") substitutions)}
      chmod +x $out/bin/${name}
    '';
}
