MAIN = thesis
OUTDIR = out

.PHONY: all clean puml

all:
	latexmk -pdf -outdir=$(OUTDIR) $(MAIN).tex

clean:
	latexmk -C -outdir=$(OUTDIR) $(MAIN).tex
	rm -rf $(OUTDIR)

puml:
	PLANTUML_LIMIT_SIZE=8192 plantuml -dots -o ../images ./uml/*.puml
