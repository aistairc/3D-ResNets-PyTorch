import argparse
import matplotlib.pyplot as plt
import numpy as np


def plot_loss(log_train, log_valid, output=None, lim_loss=None, lim_acc=None):
    train_data = np.loadtxt(log_train, skiprows=1)
    epoch = train_data[:,0]
    train_loss = train_data[:,1]
    train_acc = train_data[:,2]
    lr = train_data[:,3]

    valid_data = np.loadtxt(log_valid, skiprows=1)
    valid_loss = valid_data[:,1]
    valid_acc = valid_data[:,2]
    
    fig = plt.figure(figsize=(6,4))
    ax1 = plt.subplot2grid((4,1), (0,0), rowspan=3)
    ax3 = plt.subplot2grid((4,1), (3,0))
    cmap = plt.get_cmap('tab10')
    ax1.plot(epoch, train_loss, '-', c=cmap(0), lw=1, label='train_loss')
    ax1.plot(epoch, valid_loss, '--', c=cmap(0), lw=1, label='valid_loss')
    ax1.set_ylabel('loss', color=cmap(0))
    if lim_loss:
        ax1.set_ylim(*lim_loss)
    ax1.set_yscale('log')
    ax1.tick_params(axis='x', labelbottom=False)
    ax1.legend(loc='lower right', fontsize=8)
    
    ax2 = ax1.twinx()
    ax2.plot(epoch, train_acc, '-', c=cmap(1), lw=1, label='train_acc')
    ax2.plot(epoch, valid_acc, '--', c=cmap(1), lw=1, label='valid_acc')
    ax2.set_ylabel('accuracy', color=cmap(1))
    if lim_acc:
        ax2.set_ylim(*lim_acc)
    ax2.set_yscale('log')
    ax2.legend(loc='upper right', fontsize=8)
    
    ax3.plot(epoch, lr, lw=1)
    ax3.set(xlabel='epoch', ylabel='lr', yscale='log')
    plt.subplots_adjust(hspace=0, right=0.85)

    if output:
        fig.savefig(output)


def get_opts():
    p = argparse.ArgumentParser()
    p.add_argument('--log_train', type=str, default='train.log', help='path to train log (*.log)')
    p.add_argument('--log_valid', type=str, default='val.log', help='path to valid log (*.log)')
    p.add_argument('--loss_max', type=float, default=None, help='set the maximum loss axis')
    p.add_argument('--loss_min', type=float, default=None, help='set the minimum loss axis')
    p.add_argument('--accuracy_max', type=float, default=None, help='set the maximum accuracy axis')
    p.add_argument('--accuracy_min', type=float, default=None, help='set the minimum accuracy axis')
    p.add_argument('--output', type=str, default=None, help='path to the output (*.png)')
    return p.parse_args()


if __name__ == '__main__':
    opt = get_opts()
    plot_loss(
        opt.log_train,
        opt.log_valid,
        opt.output,
        [opt.loss_min, opt.loss_max],
        [opt.accuracy_min, opt.accuracy_max]
    )
    
