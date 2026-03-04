.PHONY: test-e2e clean
${HOME}/.pixi/bin/pixi:
	curl -sSL https://pixi.sh/install.sh | sh

test-e2e: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf -profile docker,test -resume

test-e2e-snapshot: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nf-test test --verbose --profile test,docker

test-e2e-update-snapshot: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nf-test test tests/default.nf.test --verbose --update-snapshot --profile test,docker

lint: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow lint . -format 

clean:
	rm -rf work