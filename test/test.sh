#!/usr/bin/env sh

# Type checking everything...
for i in example/*.mo   ; do $(dfx cache show)/moc $(vessel sources) --check $i ; done
for i in metascore/*.mo ; do $(dfx cache show)/moc $(vessel sources) --check $i ; done
for i in src/*.mo       ; do $(dfx cache show)/moc $(vessel sources) --check $i ; done
for i in test/*.mo      ; do $(dfx cache show)/moc $(vessel sources) -r $i ; done
