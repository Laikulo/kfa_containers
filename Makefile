all: builders kltest/.built


machines := linux avr ar100 arm rp2040 pru

builders: $(foreach machine,$(machines),kfa_build_$(machine)/.built)

layers: $(foreach machine,$(machines),kfa_build_$(machine).sfs) klipper_src.sfs

.PHONEY: all builders clean layers

kfa_buildbase/.built: kfa_buildbase/Containerfile 
	podman build -t kfa_buildbase kfa_buildbase
	touch $@

%/.built: %/Containerfile kfa_buildbase/.built
	podman build -t $* $*
	touch $@

klipper_src.sfs: klipper_src/.built
	bin/extract-base-layer klipper_src

base.sfs: kfa_buildbase/.built
	bin/extract-base-layer kfa_buildbase

%.sfs: %/.built base.sfs
	bin/extract-delta kfa_buildbase $*

clean:
	rm -fv kfa_build_*/.built kfa_buildbase/.built

