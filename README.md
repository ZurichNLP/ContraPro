ContraPro
---------

`ContraPro` is a large-scale test set meant to
- evaluate a specific discourse phenomenon: pronoun translation - automatically
- promote contrastive evaluation of machine translation systems

The test set allows for a targeted evaluation of **English--German** pronoun translation, with a _contrastive_ set of translations.

Please note: this repository does not contain any OpenSubtitles data. Instead, it includes code that automatically downloads resources.

Contrastive Evaluation
----------------------

Contrastive evaluation means to use a trained translation model to produce _scores_. Crucially, it does not involve any translation;
the translations are already given. Any translation system evaluated with this method must be able to provide model scores (negative log probabilities) for existing translations.

The input for scoring is a sentence pair, and the output is a single number. For instance:

    ("Say, if you get near a song, play it.", "Wenn Ihnen ein Song über den Weg läuft, spielen Sie ihn einfach.") -> 0.1975

The key idea of contrastive evaluation is to compare this score (`0.1975` in the example) to the score obtained with another pair of sentences,
where the translation is _corrupted_ in a certain way. In our case, we replace correct pronouns with wrong ones, as in:

    "Wenn Ihnen ein Song über den Weg läuft, spielen Sie es einfach."

And if a translation model gives lower scores to those _contrastive_ pairs, as in, for example:

    ("Say, if you get near a song, play it.", "Wenn Ihnen ein Song über den Weg läuft, spielen Sie es einfach.") -> 0.0043

We refer to this as a "correct decision" by the model. If this happens consistently, we conclude that the model can
discriminate between good and bad translations. 


Usage Instructions
------------------

Download ContraPro, for instance by cloning:

    git clone https://github.com/ZurichNLP/ContraPro
    cd ContraPro

Download Opensubtitles2018 and extract documents, preferably by just running this predefined script:

    ./setup_opensubs.sh

Extract raw text (plus context) for the ContraPro test set. Note that you can choose the number of context sentences according to what your translation system supports: a sentence-level system does not see any context, a context-aware system might observe 1 to n sentences as context.

    perl conversion_scripts/json2text_and_context.pl --source en --target de --dir \
    [/path/to/OpenSubtitles_with_document_splitting, e.g. "documents"] --json contrapro.json --context 1

The previous step will produce 4 files:

- `contrapro.text.{en,de}`: Source and target sentences, one sentence per line.
- `contrapro.context.{en,de}`: Source and target contexts, one sentence per line. If a sentence in `contrapro.text.{en,de}` has no context (e.g. because it is the first sentence in a document), this corresponds to an _empty line_ in `contrapro.context.{en,de}`.

Apply the preprocessing necessary for your system, and score each line in `contrapro.text.de` with your translation system (conditioned on the source in `contrapro.text.en`, and the context in `contrapro.context.{en,de}` - it is your responsibility to pass these in the appropriate format to your system).

Use the scores produced in the previous step (one per line) to evaluate your system. By default, lower scores are interpreted as better. If your system produces scores where higher is better, add the argument `--maximize`

    python evaluate.py --reference contrapro.json --scores [/path/to/your/scores]


Publication
-----------

If you use ContraPro, please cite the following paper:

Mathias Müller; Annette Rios; Elena Voita; Rico Sennrich (2018). A Large-Scale Test Set for the Evaluation of Context-Aware Pronoun Translation in Neural Machine Translation. In WMT 2018. Brussels, Belgium. http://www.statmt.org/wmt18/pdf/WMT007.pdf

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
