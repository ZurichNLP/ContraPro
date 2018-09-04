ContraPro
---------

A Large-Scale Test Set for the Evaluation of Context-Aware Pronoun Translation in Neural Machine Translation

This test set allows for a targeted evaluation of English--German pronoun translation.
Evaluation is contrastive, and the translation system that is evaluated is expected to provide scores (translation probabilities) for a set of given translation hypotheses.

Usage Instructions
------------------

- download ContraPro:

`https://github.com/ZurichNLP/ContraPro`

- download Opensubtitles2016 and extract documents (FINAL INSTRUCTIONS TO BE INCLUDED)

- extract raw text (plus context) for ContraPro test set. Note that you can choose the number of context sentences according to what your translation system reports

`perl conversion_scripts/json2text_and_context.pl --source en --target de --dir /path/to/OpenSubtitles_with_document_splitting --json contrapro.json --context 1`

- the previous step will produce 4 files: contrapro.context.{en,de} and contrapro.text.{en,de}. Apply the preprocessing necessary for your system, and score each line in contrapro.text.de with your translation system (conditioned on the source in contrapro.text.en, and the context in contrapro.context.{en,de} - it is your responsibility to pass these in the appropriate format to your system).

- use the scores produced in the previous step (one per line), evaluate your system. By default, lower scores are interpreted as better. If your system produces scores where higher is better, add the argument `--maximize`

`python evaluate.py --reference contrapro.json --scores /path/to/your/scores`


Publication
---------

if you use ContraPro, please cite the following paper:

Mathias Müller; Annette Rios; Elena Voita; Rico Sennrich (2018). A Large-Scale Test Set for the Evaluation of Context-Aware Pronoun Translation in Neural Machine Translation. In WMT 2018. Brussels, Belgium. 

```
@inproceedings{mueller2018,
address = "Brussels, Belgium",
author = "M{\"u}ller, Mathias and Rios, Annette and Voita, Elena and Sennrich, Rico",
booktitle = "{WMT 2018}",
publisher = "Association for Computational Linguistics",
title = "{A Large-Scale Test Set for the Evaluation of Context-Aware Pronoun Translation in Neural Machine Translation}",
year = "2018"
}
```
