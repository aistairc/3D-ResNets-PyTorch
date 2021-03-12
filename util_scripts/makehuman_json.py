import argparse
import glob
import json
import os
import pprint
import time


def make_annotation(labels):
    ret = {'labels': None, 'database': {}}
    ret['labels'] = list(labels.keys())

    for label, paths in labels.items():
        num_inst = len(paths)
        num_valid = num_test = num_inst // 10
        num_train = num_inst - num_valid - num_test

        for i, path in enumerate(paths):
            inst_id = os.path.basename(path)

            *_, end_frame = inst_id.split('-end')
            end_frame = int(end_frame)

            if i < num_train:
                subset = 'training'
            elif i < num_train + num_valid:
                subset = 'validation'
            else:
                subset = 'testing'

            inst = {
                inst_id: {
                    'subset': subset,
                    'video_path': path,
                    'annotations': {
                        'label': label,
                        'segment': [
                            2,
                            end_frame
                        ]
                    }
                }
            }
            ret['database'].update(inst)

    return ret


def select_videos(opt):
    dataset_dir = f'{opt.dataset}_videos'
    label_dir = os.path.join(opt.root, dataset_dir, opt.img_type, '*')
    label_paths = glob.glob(label_dir)

    ret = {}
    for label_path in label_paths:
        label = os.path.basename(label_path)
        if opt.mocap_labels and label in opt.mocap_labels.keys():
            label = opt.mocap_labels[label]['label']

        inst_paths = glob.glob(os.path.join(label_path, '*'))
        for inst_path in inst_paths:
            inst_id = os.path.basename(inst_path)
            *_, endframe = inst_id.split('-end')
            endframe = int(endframe)
            if endframe - 1 < opt.min_frames:
                continue

            if label in ret.keys():
                ret[label].append(inst_path)
            else:
                ret.update({label: [inst_path]})

    for k, v in ret.copy().items():
        if len(v) < opt.min_inst or (opt.blacklist and k in opt.blacklist):
            ret.pop(k)

    return ret


def stat(s):
    for cls, ins in sorted(s.items(), key=lambda x: x[0]):
        print(f'{cls}: {len(ins)}')


def get_opts():
    p = argparse.ArgumentParser()
    p.add_argument('--root', type=str, default='data')
    p.add_argument('--dataset', type=str, default='makehuman')
    p.add_argument('--img_type', type=str, default='jpg')
    p.add_argument('--min_inst', type=int, default=10)
    p.add_argument('--min_frames', type=int, default=16)
    p.add_argument('--mocap_labels', type=str, default=None)
    p.add_argument('--blacklist', type=str, default=None)
    p.add_argument('--check', action='store_true')
    return p.parse_args()


if __name__ == '__main__':
    opt = get_opts()

    mocap_labels_path = os.path.join(opt.root, 'mocap_labels.json')
    if opt.mocap_labels:
        mocap_labels_path = opt.mocap_labels

    blacklist_path = os.path.join(opt.root, 'blacklist.txt')
    if opt.blacklist:
        blacklist_path = opt.blacklist

    if os.path.exists(mocap_labels_path):
        with open(mocap_labels_path, 'r') as f:
            opt.mocap_labels = json.load(f)
    else:
        opt.mocap_labels = None

    if os.path.exists(blacklist_path):
        with open(blacklist_path, 'r') as f:
            opt.blacklist = f.read().splitlines()
    else:
        opt.blacklist = None

    s = select_videos(opt)

    if opt.check:
        stat(s)
        print('labels:', list(s.keys()))
        print('blacklist:', opt.blacklist)
        print('# of classes:', len(s.keys()))
        print('# of instances:', len(sum(s.values(), [])))
    else:
        a = make_annotation(s)

        print('# of classes:', len(a['labels']))
        print('# of instances:', len(a['database']))

        dst = os.path.join(opt.root, opt.dataset + '.json')
        with open(dst, 'w') as f:
            json.dump(a, f, indent=4)
        print('filepath:', os.path.abspath(dst))
        print('done!')
