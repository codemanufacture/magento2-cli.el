EMACS ?= emacs

ELS = magento2-cli.el
ELCS = $(ELS:.el=.elc)

%.elc: %.el
	$(EMACS) --batch -L $(ELS) -f batch-type-compile $<

all: $(ECLS)

clean:
	rm -f $(ELCS)

test: clean all
	$(EMACS) --batch -l $(ELS) -l magento2-cli-test.el -f ert-run-tests-batch-and-exit

.PHONY: all clean test
