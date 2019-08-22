#!/usr/bin/python3
# -*- coding: utf-8 -*-
# Author: Annette Rios, Rico Sennrich

from __future__ import division, print_function, unicode_literals
import sys
if sys.version_info[0] < 3:
    reload(sys)
    sys.setdefaultencoding("utf8")
import json
import argparse
import codecs
from collections import defaultdict, OrderedDict
from operator import gt, lt
import scipy
import scipy.stats

# usage: python evaluate.py errors.json < scores
# by default, lower scores (closer to zero for log-prob) are better

def count_errors(reference, scores, maximize, verbose=False):
    """read in scores file and count number of correct decisions"""

    reference = json.load(reference)

    results = {'by_category': defaultdict(lambda: defaultdict(int)),
               'by_intrasegmental': defaultdict(lambda: defaultdict(int)),
               'by_ante_distance': defaultdict(lambda: defaultdict(int)),
               'ante_dist_stats' : defaultdict(lambda: defaultdict(int))
              }

    if maximize:
        better = gt
    else:
        better = lt

    readlines =0

    for count, sentence in enumerate(reference):
        #print(count)
        score = float(scores.readline())

        readlines +=1

        all_better = True

        category = sentence['src pronoun'].lower() + ":" + sentence['ref pronoun'].lower()
        results['by_category'][category]['total'] += 1
        ante_dist = sentence['ante distance']
        if ante_dist > 3:
            ante_dist = ">3"
        results['by_ante_distance'][str(ante_dist)]['total'] +=1
        results['ante_dist_stats'][str(ante_dist)][category] +=1
        intrasegmental = sentence['intrasegmental'] ## can be true, false or null (in this case will be returned as None)
        results['by_intrasegmental'][intrasegmental]['total'] +=1
        for error in sentence['errors']:
            errorscore = float(scores.readline())
            readlines +=1
            if not better(score, errorscore):
                    all_better = False

        if all_better:
            results['by_category'][category]['correct'] += 1
            results['by_intrasegmental'][intrasegmental]['correct'] += 1
            results['by_ante_distance'][str(ante_dist)]['correct'] += 1

        if verbose and ante_dist ==0:
                if all_better:
                    print("correct")
                else:
                    print("wrong")
                print("ante dist: {}".format(ante_dist))
                print("ref prn {}".format(sentence["ref pronoun"]))
                print("source: {}".format(sentence["src segment"]))
                print("ref: {}".format(sentence["ref segment"]))
                print("src ante: {}".format(sentence["src ante phrase"]))
                print("ref ante: {}".format(sentence["ref ante phrase"]))
                print()

    return results 

def get_scores(category):
    correct = category['correct']
    total = category['total']
    if total:
        accuracy = correct/total
    else:
        accuracy = 0
    return correct, total, accuracy



def print_statistics(results):

    correct = sum([results['by_category'][category]['correct'] for category in results['by_category']])
    total = sum([results['by_category'][category]['total'] for category in results['by_category']])
    print('{0} : {1} {2} {3}'.format('total', correct, total, correct/total))


def print_statistics_by_category(results):

    for category in sorted(results['by_category']):
        correct, total, accuracy = get_scores(results['by_category'][category])
        if total:
            print('{0} : {1} {2} {3}'.format(category, correct, total, accuracy))

def print_statistics_by_intrasegmental(results):

    for intrasegmental in sorted(results['by_intrasegmental']):
        correct, total, accuracy = get_scores(results['by_intrasegmental'][intrasegmental])
        if total:
            print('{0} : {1} {2} {3} '.format(intrasegmental, correct, total, accuracy))

def print_statistics_by_distance(results):

    for distance in sorted(results['by_ante_distance']):
        correct, total, accuracy = get_scores(results['by_ante_distance'][distance])
        if total:
            print('{0} : {1} {2} {3} '.format(distance, correct, total, accuracy))

def print_ante_distance_stats(results):

    for distance in sorted(results['ante_dist_stats']):
        print('ante distance {0} :'.format(distance))
        for category in sorted(results['ante_dist_stats'][distance]):
            total = results['ante_dist_stats'][distance][category]
            if total:
                print('{} {} '.format(category, total))

def main(reference, scores, maximize, verbose):

    results = count_errors(reference, scores, maximize, verbose )

    print_statistics(results)
    print()
    print('statistics by error category')
    print_statistics_by_category(results)
    print()  
    print('statistics by intrasegmental')
    print_statistics_by_intrasegmental(results)
    print() 
    print('statistics by ante distance')
    print_statistics_by_distance(results)
    print() 
    print('ante distance per pronoun pairs')
    print_ante_distance_stats(results)

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--verbose', '-v', action="store_true", help="verbose mode (prints out all wrong classifications)")
    parser.add_argument('--maximize', action="store_true", help="Use for model where higher means better (probability; log-likelhood). By default, script assumes lower is better (negative log-likelihood).")
    parser.add_argument('--reference', '-r', type=argparse.FileType('r'),
                        required=True, metavar='PATH',
                        help="Reference JSON file")
    parser.add_argument('--scores', '-s', type=argparse.FileType('r'),
                        default=sys.stdin, metavar='PATH',
                        help="File with scores (one per line)")

    args = parser.parse_args()

    # read/write files as UTF-8
    args.reference = codecs.open(args.reference.name, encoding='utf-8')

    #enc = sys.getdefaultencoding()
    #print('enc:', enc)
    main(args.reference, args.scores, args.maximize, args.verbose)
