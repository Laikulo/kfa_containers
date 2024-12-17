all: builders kltest/.built

machines := linux avr ar100

builders: $(foreach machine,$(machines),kfa_build_$(machine)/.built)

.PHONEY: all builders clean

kfa_buildbase/.built: kfa_buildbase/Containerfile 
	podman build -t kfa_buildbase kfa_buildbase
	touch $@

%/.built: %/Containerfile kfa_buildbase/.built
	podman build -t $* $*
	touch $@

kltest/.built: kfa_build_linux/.built klipper_src/.built


clean:
	rm -fv kfa_build_*/.built kfa_buildbase/.built

