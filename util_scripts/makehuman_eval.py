import argparse
import json
import matplotlib.pyplot as plt
import numpy as np


class MakeHumanAnnotations:
    def __init__(self, annotation_path):
        self._annotations = self.load(annotation_path)
        
    def load(self, fname):
        with open(fname, 'r') as f:
            return json.load(f)

    def annotations(self):
        return self._annotations['database']
            
    def labels(self):
        return sorted(self._annotations['labels'])

    def count_label(self, label, subset='all'):  # subset (training|validation|testing)
        ret = 0
        for k, v in self.annotations().items():
            if v['annotations']['label'] == label and v['subset'] == subset:
                ret += 1
            elif v['annotations']['label'] == label and subset == 'all':
                ret += 1
                
        return ret
    
    def get_correct_label(self, video_id):
        return self.annotations()[video_id]['annotations']['label']
                                                                                                                                                    
class MakeHumanResults:
    def __init__(self, result_path, annotation_path):
        self._results = self.load(result_path)  # average option must be true (cf. --no_average)
        self._annotations = MakeHumanAnnotations(annotation_path)
    
    def __len__(self):
        return len(self._results['results'])

    def __str__(self):
        return json.dumps(self.results)

    def load(self, fname):
        with open(fname, 'r') as f:
            return json.load(f)
        
    def results(self):
        return self._results['results']

    def labels(self):
        return self._annotations.labels()

    def _confusion_matrix(self):
        ret = {}
        
        labels = self.labels()
        for gt in labels:
            for pred in labels:
                ret[f'{gt} X {pred}'] = []
                
        for vid, preds in self.results().items():
            gt = self._annotations.get_correct_label(vid)
            for pred in preds:
                assert pred['label'] in labels, f"label not found: {pred['label']}"
                ret[f"{gt} X {pred['label']}"].append(pred['score'])
                
        return ret, labels
    
    def confusion_matrix(self):
        cmat, labels = self._confusion_matrix()
        
        for k, v in cmat.items():
            cmat[k] = np.mean(v)
            
        n = len(labels)
        ret = np.zeros((n,n))
        for i, gt in enumerate(labels):
            for j, pred in enumerate(labels):
                ret[i,j] = cmat[f'{gt} X {pred}']
                
        return ret, labels

    def plot_confusion_matrix(self, title=None, output=None):
        hmap, labels = self.confusion_matrix()
        n = len(labels)

        fig, ax = plt.subplots(figsize=(6,5))
        im = ax.imshow(hmap, interpolation='none', vmin=0, vmax=1)
        if title:
            ax.set_title(title, fontsize=10)
        ax.set_xlabel('predicted label')
        ax.set_xticks(range(n))
        ax.set_xticklabels(labels, rotation=90, fontsize=9)
        ax.set_ylabel('true label')
        ax.set_yticks(range(n))
        ax.set_yticklabels(labels, fontsize=9)
        fig.colorbar(im, ax=ax)
        fig.tight_layout()
        
        if output:
            fig.savefig(output)
        
    def calc_topk_accuracy(self, k):
        ret = 0
        
        labels = self.labels()
        for vid, preds in self.results().items():
            gt = self._annotations.get_correct_label(vid)
            for pred in preds[:k]:
                assert pred['label'] in labels, f"label not found: {pred['label']}"
                if gt == pred['label']:
                    ret += 1
                    break
                
        ret /= len(self.results())
        
        return ret


def get_opts():
    p = argparse.ArgumentParser()
    p.add_argument('--result_path', type=str, help='path to the test result (*.json)')
    p.add_argument('--annotation_path', type=str, help='path to the annotation (*.json)')
    p.add_argument('--output', type=str, default=None, help='path to the output file (*.png)')
    p.add_argument('--title', type=str, default='Confusion matrix', help='set graph tile')
    return p.parse_args()


if __name__ == '__main__':
    opt = get_opts()
    mhr = MakeHumanResults(opt.result_path, opt.annotation_path)
    top1 = mhr.calc_topk_accuracy(1)
    top5 = mhr.calc_topk_accuracy(5)
    mhr.plot_confusion_matrix(f'{opt.title}, top-1: {top1:.1%}, top-5: {top5:.1%}', opt.output)
