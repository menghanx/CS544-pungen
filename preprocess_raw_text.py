import argparse
import spacy
import re
from unidecode import unidecode
from tqdm import tqdm

#nlp = spacy.load('en_core_web_sm', disable=['tagger', 'parser', 'ner'])
nlp = spacy.load('en_core_web_sm', disable=['ner'])
#nlp_tmp = spacy.load('en_core_web_sm')
#tagger = nlp_tmp.get_pipe("tagger")
#for name in ('sentencizer', 'tagger'):
#    nlp.add_pipe(nlp.create_pipe(name))
#nlp.add_pipe(nlp.create_pipe('sentencizer'))
#nlp.add_pipe(nlp_tmp.get_pipe("lemmatizer"))
#nlp.get_pipe("lemmatizer")
#nlp.add_pipe(tagger)

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input')
    parser.add_argument('--output')
    parser.add_argument('--min-len', type=int, default=5, help='minimum sentence length')
    parser.add_argument('--max-len', type=int, default=30, help='maximum sentence length')
    args = parser.parse_args()
    return args

def sentence_iter(file_):
    with open(file_, 'r', errors='ignore') as fin:
        cache = []
        for line in fin:
            line = re.sub('\s+', ' ', unidecode(line.strip()))
            cache.append(line)
            if len(cache) == 200:
                docs = nlp.pipe(cache)
                for doc in docs:
                    for s in doc.sents:
                        yield s
                cache = []
        if cache:
            docs = nlp.pipe(cache)
            for doc in docs:
                for s in doc.sents:
                    yield s

def main(args):
    count = 0
    with open(args.output, 'w') as fout, open(args.input, 'r') as fin:
        for s in tqdm(sentence_iter(args.input)):
            #s = s.strip().split()
            if len(s) >= args.min_len and len(s) <= args.max_len:
                l = ['{}|{}|{}'.format(token.text,token.lemma_, token.pos_) for token in s]
                fout.write(' '.join(l) + '\n')
                count += 1

if __name__ == '__main__':
    args = parse_args()
    main(args)

