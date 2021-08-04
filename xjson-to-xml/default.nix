{ stdenv
, python3
 } :
stdenv.mkDerivation {
  pname = "xjson-to-xml";
  version= "0.1"; 
  src = ./.;

  buildInputs = [ python3 ];
  installPhase = ''
    mkdir -p $out/bin
    cp main.py $out/bin/xjson-to-xml
    chmod a+x $out/bin/xjson-to-xml
  '';
}
  
