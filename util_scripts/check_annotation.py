import argparse
import json


class AnnotationData:
    def __init__(self, fname):
        self.fname = fname
        self.data = self.load(fname)

    def __str__(self):
        return json.dumps(self.data)

    def load(self, fname):
        with open(fname, 'r') as f:
            return json.load(f)

    def n_classes(self):
        return len(self.data['labels'])

    def n_instances(self):
        return len(self.data['database'])

    def labels(self):
        return self.data['labels']


def get_opts():
    p = argparse.ArgumentParser()
    p.add_argument('--annotation_path', type=str)
    p.add_argument('--n_classes', action='store_true')
    p.add_argument('--n_instances', action='store_true')

    return p.parse_args()

if __name__ == '__main__':
    opt = get_opts()

    a = AnnotationData(opt.annotation_path)
    num_cls = a.n_classes()
    num_ins = a.n_instances()

    if opt.n_classes:
        print(num_cls)
    elif opt.n_instances:
        print(num_ins)
    else:
        print(f'# of classes: {num_cls}')
        print(f'# of instances: {num_ins}')
