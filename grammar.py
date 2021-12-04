import json
import argparse
import language_tool_python
tool = language_tool_python.LanguageTool('en-US')

parser = argparse.ArgumentParser()
parser.add_argument('--input')
parser.add_argument('--output')
args = parser.parse_args()

f = open(args.input,'r')
input = json.loads(f.read())

def sort(e):
    # print(e)
    if 'score' in e:
        return float(e['score'])
    else:
        return -1.0


 
def setScore(param, input):
    for example in input:
        example['results'].sort(key=sort, reverse=True)
        example['results'] = example['results'][:10]
        # print (template_list)
        for template in example['results']:
            if 'output' in template:
                senetence = ' '.join(template['output'])
                matches = tool.check(senetence)
                score = (len(template['output']) - len(matches)) / len(template['output'])
                template[param] = score * 5
                # template['grammar-before'] = template['grammar-before'] * 5
                print(score)

setScore('grammar-before', input)

with open(args.output, 'w', encoding='utf-8') as f:
    json.dump(input, f,indent=4)