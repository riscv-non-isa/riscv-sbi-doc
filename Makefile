#
# Build usable documents
#

ASCIIDOCTOR = asciidoctor
TARGETS = riscv-sbi.pdf
TARGETS += riscv-sbi.html

.PHONY: all
all: $(TARGETS)

%.html: %.adoc
	$(ASCIIDOCTOR) -d book -b html $<

%.pdf: %.adoc
	$(ASCIIDOCTOR) -d book -r asciidoctor-pdf -b pdf $<

.PHONY: clean
clean:
	rm -f $(TARGETS)

.PHONY: install-debs
install-debs:
	sudo apt-get install pandoc asciidoctor ruby-asciidoctor-pdf

.PHONY: install-rpms
install-rpms:
	sudo dnf install pandoc rubygem-asciidoctor rubygem-asciidoctor-pdf
