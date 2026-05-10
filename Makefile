all: layers kltest/.built builders.oci

PODMAN_PLATFORM = linux/amd64

PODMAN = podman
TAR = tar

machines := linux avr ar100 arm rp2040 pru

builders: $(foreach machine,$(machines),kfa_build_$(machine)/.built)

layers: $(foreach machine,$(machines),kfa_build_$(machine).sfs)

.PHONEY: all builders clean layers

kfa_buildbase/.built: kfa_buildbase/Containerfile 
	$(PODMAN) build --platform $(PODMAN_PLATFORM) -t kfa_buildbase kfa_buildbase
	$(PODMAN) $@

kltest/.built: kltest/Containerfile klipper_src/.built
	$(PODMAN) build --platform $(PODMAN_PLATFORM) -t kltest kltest
	touch $@

%/.built: %/Containerfile kfa_buildbase/.built
	$(PODMAN) build --platform $(PODMAN_PLATFORM) -t $* $*
	touch $@

oci-push: $(foreach machine,$(machines),push-$(machine)) push-base

push-%: kfa_build_%/.built
	$(PODMAN) push kfa_build_$* $(OCI_REPO)/kfa/build/$*:$(OCI_TAG)

push-base: kfa_buildbase/.built
	$(PODMAN) push kfa_buildbase $(OCI_REPO)/kfa/build/base:$(OCI_TAG)


klipper_src.sfs: klipper_src/.built
	bin/extract-base-layer klipper_src

kfa_buildbase.sfs: kfa_buildbase/.built
	bin/extract-base-layer kfa_buildbase

%.sfs: %/.built kfa_buildbase/.built
	bin/extract-delta kfa_buildbase $*

builders.oci: builders kfa_buildbase/.built
	$(PODMAN) image save -m -o $@ kfa_buildbase $(foreach machine,$(machines),kfa_build_$(machine))

clean:
	rm -fv kfa_build_*/.built kfa_buildbase/.built kfa_*.sfs builders.oci

oras-attach:
	oras attach --artifact-type=application/vnd.kfa.environment \
		$(ORAS_MANIFEST) \
		kfa_buildbase.sfs:application/vnd.kfa.fs.base+squashfs \
		kfa_build_ar100.sfs:application/vnd.kfa.fs.layer+squashfs \
		kfa_build_arm.sfs:application/vnd.kfa.fs.layer+squashfs \
		kfa_build_avr.sfs:application/vnd.kfa.fs.layer+squashfs \
		kfa_build_linux.sfs:application/vnd.kfa.fs.layer+squashfs \
		kfa_build_pru.sfs:application/vnd.kfa.fs.layer+squashfs \
		kfa_build_rp2040.sfs:application/vnd.kfa.fs.layer+squashfs

