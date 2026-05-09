all: layers kltest/.built builders.oci

PODMAN_PLATFORM = linux/amd64

machines := linux avr ar100 arm rp2040 pru

builders: $(foreach machine,$(machines),kfa_build_$(machine)/.built)

layers: $(foreach machine,$(machines),kfa_build_$(machine).sfs)

.PHONEY: all builders clean layers

kfa_buildbase/.built: kfa_buildbase/Containerfile 
	podman build --platform $(PODMAN_PLATFORM) -t kfa_buildbase kfa_buildbase
	touch $@

kltest/.built: kltest/Containerfile klipper_src/.built
	podman build --platform $(PODMAN_PLATFORM) -t kltest kltest
	touch $@

%/.built: %/Containerfile kfa_buildbase/.built
	podman build --platform $(PODMAN_PLATFORM) -t $* $*
	touch $@


klipper_src.sfs: klipper_src/.built
	bin/extract-base-layer klipper_src

kfa_buildbase.sfs: kfa_buildbase/.built
	bin/extract-base-layer kfa_buildbase

%.sfs: %/.built kfa_buildbase/.built
	bin/extract-delta kfa_buildbase $*

builders.oci: builders kfa_buildbase/.built
	podman image save -m -o $@ kfa_buildbase $(foreach machine,$(machines),kfa_build_$(machine))

clean:
	rm -fv kfa_build_*/.built kfa_buildbase/.built kfa_*.sfs builders.oci

