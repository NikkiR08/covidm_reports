
-include local.makefile

COVIDMPATH ?= ../covidm
REPDIR ?= ~/Dropbox/Covid_lmic/reports
DATADIR ?= ~/Dropbox/covidm_reports
INTINPUTDIR := ${DATADIR}/interventions/inputs

${REPDIR} ${DATADIR}:
	mkdir -p $@

R = Rscript $^ $@

# This file forms the reference locales for which we generate reports

LMIC.txt: X-LMIC.R
	Rscript $^ ${COVIDMPATH} $@


# This is for generating contact matrices

LMICcontact_matrices.txt: LMIC.txt
	sed "s/ //g" $^ > $@-tmp
	tr '[:upper:]' '[:lower:]' < $@-tmp > $@
	rm $@-tmp
	sed -i '' "s/$$/\/contact_matrices\.rds/" $@

CMS := $(addprefix ${INTINPUTDIR}/,$(shell cat LMICargs.txt))

allcontactmatrices: ${CMS} | LMICcontact_matrices.txt

${INTINPUTDIR}/%/contact_matrices.rds: create_contact_matrices.R
	mkdir -p $(@D)
	Rscript $^ ${COVIDMPATH} $* PLACEHOLDER $@

testcm: ${INTINPUTDIR}/caboverde/contact_matrices.rds | LMICcontact_matrices.txt


LMICargs.txt: LMIC.txt
	sed "s/ //g" $^ > $@
	sed -i '' "s/$$/-res\.rds/" $@




TARS := $(addprefix ${DATADIR}/,$(shell cat LMICargs.txt))

alltars: ${TARS}

testrep: ${REPDIR}/CaboVerde.pdf

allreps: $(patsubst %-res.rds,%.pdf,$(subst ${DATADIR},${REPDIR},${TARS}))

${DATADIR}/%-res.rds: X2-LMIC.R LMICargs.txt LMIC.txt | ${DATADIR}
	Rscript $< .. 100 $(filter-out $<,$^) $@

${REPDIR}/%.pdf: report.R ${DATADIR}/%-res.rds report-template.Rmd | ${REPDIR}
	${R}

INTCOUNTRIES := Kenya Uganda Zimbabwe
#INTSCENARIOS := $(foreach C,${INTCOUNTRIES},$(patsubst %,%_${C},$(shell seq 2 189)))
UNMITSCENARIOS := $(patsubst %,1_%,${INTCOUNTRIES})
#TSTSCENARIOS := $(patsubst %,5_%,${INTCOUNTRIES})

precursors: $(patsubst %,${DATADIR}/interventions/cases_sceni_%.rds,${UNMITSCENARIOS})

${DATADIR}/interventions/cases_sceni_%.rds: covidm_interventions_run_scenario.R helper_functions.R
	time Rscript $< ${COVIDMPATH} $(filter-out $<,$^) $(subst _, ,$*) ${INTINPUTDIR} $@

# consolidate.R actually consolidates everything
consolidate: ${DATADIR}/interventions/Uganda_consolidated.rds

# TODO: also rm the now-consolidated files?
${DATADIR}/interventions/%_consolidated.rds: consolidate.R
	time Rscript $^ $(@D)


cleanrds:
	rm -f *-res.rds
