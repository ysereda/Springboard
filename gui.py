#https://docs.python.org/3/library/tkinter.html
#https://datatofish.com/entry-box-tkinter/
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from PIL import Image, ImageGrab
from tkinter import *
import tkinter as tk
import win32gui
mx = False
from keras.models import load_model
model = load_model('models/nn_50_25.ml0.e200.h5')
def predict_digit(img):
    #resize image to 28x28 pixels
    img = img.resize((28,28))
    #convert rgb to grayscale
    img = img.convert('L')
    img = np.array(img)
    #reshaping to support our model input and normalizing
    if mx: img = img.reshape(1,28,28,1)
    else: img = img.reshape(1,28*28,1)
    img = img/255.0 # make pixels 0 to 1
    img = 1 - img # negate: black background, white digit (as in training data)
    #plt.imshow(img, cmap='gray');
    #predicting the class
    res = model.predict([img])[0]
    return np.argmax(res), max(res)
class App(tk.Tk):
    def __init__(self):
        tk.Tk.__init__(self)
        # Parameters
        self.x = self.y = 0
        self.width = self.height = 60 # sizes of handwritten digit box
        self.i = 0 # counter of fixed labels
        self.cl = np.array([], dtype='float32') # corrected labels
        self.images_misclass = pd.DataFrame([], dtype='int') # incorrectly classified images
        self.n_ca = 0 # counter of correct answers
        self.n_aa = 0 # counter of all answers
        self.acc_running = 0 # running accuracy
        # Creating elements
        self.canvas = tk.Canvas(self, width=self.width, height=self.height, bg = "white", cursor="cross")
        self.label = tk.Label(self, text="Draw digit", font=("Helvetica", 48))
        self.button_classify = tk.Button(self, text = "Recognise", command =         self.classify_handwriting) 
        self.button_clear = tk.Button(self, text = "Clear", command = self.clear_all)
        self.button_fix = tk.Button(self, text = "Fix", command = self.fix)
        self.entry1 = tk.Entry(self)
        self.canvas.create_window((self.width+2,self.height+2), window=self.entry1)
        self.button_getlabel = tk.Button(self, text='Get label', command=self.get_label)
        self.button_save = tk.Button(self, text='Save corrections', command=self.save)
        self.accuracy = tk.Label(self, text="Accuracy", font=("Helvetica", 28)) # running accuracy
        # Grid structure
        self.canvas.grid(row=0, column=0, pady=2, sticky=W, )
        self.label.grid(row=0, column=1,pady=2, padx=2)
        self.button_classify.grid(row=1, column=1, pady=2, padx=2)
        self.button_clear.grid(row=1, column=0, pady=2)
        self.canvas.bind("<B1-Motion>", self.draw_lines)
        self.button_fix.grid(row=2, column=0, pady=2, padx=2)
        self.entry1.grid(row=2, column=1, pady=2, padx=2)
        self.button_getlabel.grid(row=2, column=2, pady=2, padx=2)
        self.button_save.grid(row=3, column=1, pady=2, padx=2)
        self.accuracy.grid(row=3, column=2, pady=2, padx=2)
        
    def clear_all(self):
        self.canvas.delete("all")
        self.acc_running = self.n_ca/self.n_aa
        self.accuracy.configure(text= str(int(self.acc_running*100))+'%')
    def classify_handwriting(self):
        HWND = self.canvas.winfo_id() # get the handle of the canvas
        rect = win32gui.GetWindowRect(HWND) # get the coordinate of the canvas
        im = ImageGrab.grab(rect)
        digit, acc = predict_digit(im)
        self.label.configure(text= str(digit)+', '+ str(int(acc*100))+'%')
        self.n_ca += 1
        self.n_aa += 1
    def draw_lines(self, event):
        self.x = event.x
        self.y = event.y
        r=self.width//28
        self.canvas.create_oval(self.x-r, self.y-r, self.x + r, self.y + r, fill='black')
    def get_label(self):
        '''Get and append correct label.'''
        y_label = int(self.entry1.get()) # text box gives a string
        self.cl = np.append(self.cl, y_label) # append corrected label
        print(self.i, self.cl)
        self.i = self.i + 1 # update counter of corrected labels
        self.canvas.delete("all") # clear canvas
        self.label.configure(text= 'Next image')
        self.n_ca -= 1
        self.acc_running = self.n_ca/self.n_aa
        self.accuracy.configure(text= str(int(self.acc_running*100))+'%')
    def fix(self):
        '''Get handwritten image for subsequent saving. Type instructions. Get and append correct label.'''
        global im # misclassified image
        # Grab misclassified image from canvas
        HWND = self.canvas.winfo_id() # get the handle of the canvas
        rect = win32gui.GetWindowRect(HWND) # get the coordinate of the canvas
        im = ImageGrab.grab(rect)
        # Crop image padding
        left = 2 # pixels to crop on the left
        top = 2 # pixels to crop on top
        right = self.width + left
        bottom = self.height + top
        im = im.crop((left, top, right, bottom))
        # Grayscale, reshape, negate
        im = im.convert('L') # Convert rgb to grayscale
        im = im.resize((28,28)) # Reshape to support our training model input (MNIST) and normalizing
        im = np.array(im) # convert to numeric array
        im = 255 - im # negate: black background, white digit (as in training data)
        # Append misclassified image
        self.images_misclass = self.images_misclass.append(pd.DataFrame(im.reshape(1,28*28)), ignore_index=True)
        plt.imshow(im, cmap='gray')
        # Type instructions
        self.label.configure(text="Enter label\nHit Get label", font=("Helvetica", 48))
    def save(self):
        saved_images = 'images.csv'
        saved_labels = 'labels.csv'
        #print("Saving misclassified images:", saved_images)
        pd.DataFrame(self.images_misclass).to_csv(saved_images, index=False, header=None, mode='a') # append images to file
        #print("Saving correct labels:", saved_labels)
        pd.DataFrame(self.cl).to_csv(saved_labels, index=False, header=None, mode='a') # append labels to file
        self.images_misclass = pd.DataFrame([], dtype='int') # after saving, clear the memory
        self.cl = np.array([], dtype='float32')
        self.canvas.delete("all") # clear canvas
        self.label.configure(text= 'Next image')

#if mx: model = load_model('cnn.e200.h5')
#else: model = load_model('nn.e200.h5')
app = App()
mainloop();