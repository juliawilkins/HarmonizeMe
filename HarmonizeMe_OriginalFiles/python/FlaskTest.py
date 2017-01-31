from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def HelloThere():
	return '<h1>Hello I am testing</h1>'

@app.route('/test1')
def Homepage():
	return render_template('TestRecording.html')





if __name__ == '__main__':
	app.run(debug=True)
