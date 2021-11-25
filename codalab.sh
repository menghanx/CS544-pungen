python scripts/parsed_to_tokenized.py --input data/train.txt --output /tmp/train.tokenized.txt
python scripts/parsed_to_tokenized.py --input data/valid.txt --output /tmp/valid.tokenized.txt
cat /tmp/train.tokenized.txt /tmp/valid.tokenized.txt > /tmp/sent.tokenized.txt
python -m pungen.retriever --doc-file /tmp/sent.tokenized.txt --path retriever.pkl

# 不用我们train skipgram, 否则最后找不到词汇，应该直接用他给的
# python -m pungen.wordvec.preprocess --data-dir /tmp/skipgram --corpus data/train.txt --min-dist 5 --max-dist 10 --threshold 80 --vocab /tmp/skipgram/dict.txt
# python -m pungen.wordvec.train --weights --cuda --data /tmp/skipgram/train.bin --save_dir /tmp/models --mb 3500 --epoch 15 --vocab /tmp/skipgram/dict.txt
# cp /tmp/models/sgns-e15.pt ./skipgram/model.pt; cp /tmp/skipgram/dict.txt ./skipgram/dict.txt

for split in train valid; do PYTHONPATH=. python scripts/make_src_tgt_files.py -i data/$split.txt -o /tmp/edit/$split --delete-frac 0.5 --window-size 2 --random-window-size; done; 
python -m pungen.preprocess --source-lang src --target-lang tgt --destdir /tmp/edit/bin/data --thresholdtgt 80 --thresholdsrc 80 --validpref /tmp/edit/valid --trainpref /tmp/edit/train --workers 8; mkdir combiner-data; cp /tmp/edit/bin/data/*.txt combiner-data;


for split in train valid; do PYTHONPATH=. python scripts/make_src_tgt_files.py -i data/$split.txt -o /tmp/edit/$split --delete-frac 0.5 --window-size 2 --random-window-size; done; python -m pungen.preprocess --source-lang src --target-lang tgt --destdir /tmp/edit/bin/data --thresholdtgt 80 --thresholdsrc 80 --validpref /tmp/edit/valid --trainpref /tmp/edit/train --workers 8; python -m pungen.train /tmp/edit/bin/data -a lstm --source-lang src --target-lang tgt --task edit --insert deleted --combine token --criterion cross_entropy --encoder lstm --decoder-attention True --optimizer adagrad --lr 0.01 --lr-scheduler reduce_lr_on_plateau --lr-shrink 0.5 --clip-norm 5 --max-epoch 50 --max-tokens 7000 --no-epoch-checkpoints --save-dir models --no-progress-bar --log-interval 50000; rm models/checkpoint_last.pt

python scripts/parsed_to_tokenized.py --input data/train.txt --output /tmp/train.tokenized.txt; 
python scripts/parsed_to_tokenized.py --input data/valid.txt --output /tmp/valid.tokenized.txt; 
cat /tmp/train.tokenized.txt /tmp/valid.tokenized.txt > /tmp/sent.tokenized.txt; 
NLTK_DATA=nltk_data python generate_pun.py foo --system retrieve --retriever-model retriever.pkl --doc-file /tmp/sent.tokenized.txt --skipgram-model skipgram/dict.txt skipgram/model.pt --num-candidates 500 --num-templates 100 --num-topic-word 100 --type-consistency-threshold 0.3 --pun-words pun-data/test.json --outdir results/Retrieve --scorer random --max-num-examples 100 --word-counts-path word-counts/dict.txt

python scripts/parsed_to_tokenized.py --input data/train.txt --output /tmp/train.tokenized.txt; 
python scripts/parsed_to_tokenized.py --input data/valid.txt --output /tmp/valid.tokenized.txt; 
cat /tmp/train.tokenized.txt /tmp/valid.tokenized.txt > /tmp/sent.tokenized.txt; 
python generate_pun.py foo --system retrieve+swap --retriever-model retriever.pkl --doc-file /tmp/sent.tokenized.txt --skipgram-model skipgram/dict.txt skipgram/model.pt --num-candidates 500 --num-templates 100 --num-topic-word 100 --type-consistency-threshold 0.3 --pun-words pun-data/test.json --outdir results/Retrieve+Swap --scorer random --max-num-examples 100 --word-counts-path word-counts/dict.txt

python scripts/parsed_to_tokenized.py --input data/train.txt --output /tmp/train.tokenized.txt
python scripts/parsed_to_tokenized.py --input data/valid.txt --output /tmp/valid.tokenized.txt
cat /tmp/train.tokenized.txt /tmp/valid.tokenized.txt > /tmp/sent.tokenized.txt
python generate_pun.py foo --system rule --retriever-model retriever.pkl --doc-file /tmp/sent.tokenized.txt --skipgram-model skipgram/dict.txt skipgram/model.pt --num-candidates 500 --num-templates 100 --num-topic-word 100 --type-consistency-threshold 0.3 --pun-words pun-data/test.json --outdir results/Retrieve+Swap+Topic --scorer random --max-num-examples 100 --word-counts-path word-counts/dict.txt

python scripts/parsed_to_tokenized.py --input data/train.txt --output /tmp/train.tokenized.txt; 
python scripts/parsed_to_tokenized.py --input data/valid.txt --output /tmp/valid.tokenized.txt; 
cat /tmp/train.tokenized.txt /tmp/valid.tokenized.txt > /tmp/sent.tokenized.txt; 
python generate_pun.py combiner-data --path models/checkpoint_best.pt --beam 20 --nbest 1 --unkpen 100 --task edit --system rule --retriever-model retriever.pkl --doc-file /tmp/sent.tokenized.txt --skipgram-model skipgram/dict.txt skipgram/model.pt --num-candidates 500 --num-templates 100 --num-topic-word 100 --type-consistency-threshold 0.3 --pun-words pun-data/test.json --outdir results/Retrieve+Swap+Topic+Smoother --scorer random --max-num-examples 100 --word-counts-path word-counts/dict.txt
