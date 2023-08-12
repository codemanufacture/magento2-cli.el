EMACS ?= emacs

ELS = magento2-cli.el
ELCS = $(ELS:.el=.elc)
AUTOLOADS = magento2-cli-autoloads.el

%.elc: %.el
	$(EMACS) --batch -L $(ELS) -f batch-type-compile $<

all: autoloads $(ECLS)

autoloads: $(AUTOLOADS)

$(AUTOLOADS): $(ELS)
	$(EMACS) --batch -L $(ELS) --eval \
	"(let ((user-emacs-directory default-directory)) \
	   (require 'package) \
	   (package-generate-autoloads \"magento2-cli\" (expand-file-name \".\")))"

clean:
	rm -f $(ELCS) $(AUTOLOADS)

test: clean all
	$(EMACS) --batch -l $(ELS) -l magento2-cli-test.el -f ert-run-tests-batch-and-exit

.PHONY: all autoloads clean test
