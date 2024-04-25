s.boot;


// Neural Network Flucoma component for SC

/*


Order of steps+ Things to note:


1. val is taking values from the outputbuffer, which has many columns of separate values. This allows you to take as many values as you want for different parameters. For example, if your output JSON file has 7 columns, then by inputting val[0]- val[7], you can cycle through 7 different parameters

2. You can begin your predict mechanism when the "loss%" hits a stabilisation point where it decreases negligibly. Keeping it to a floating point number below 1 is ideal. Decent error rates are between 0 and 0.5, the best are between 0 and 0.05

3. Move your slider1 only when the predicting button has been set to 'on'

4. Execute each line in the dataset and buffer allocation section independently. SC doesn't seem ti recognize a whole parentheses exeute here

5. Hit your normalize function AFTER the data sets are loaded. If a dataset is not printed out, that means your JSON files are not formatted correctly. Always check the "data" parameter when you are typing data into the file and do not alter it.

6. For your Neural network to actually train, the spatial mapping need to be the same i.e the JSON files need the same number of rows. Columns can be as many as you like but rows need to be the exact same for the train button to work.

7. Both input and output values need to be normalized for the training to go to a sub 1 loss percentage i.e actually get trained. However, this can fuck up your values if you are not careful. It's advisable to not use more than a single row and to magnify your outputs

8. You have to actually load the MLP into the GUI for this thing to work

9. The final kicker is that your Buffer needs three important things defined. The bufnums should be two different numbers, your numframes should 1 or 2 at max and the numchannels value should be set to 1 for both.


*/



//First, execute variables into SC environment

FluidDataSet.version

//Defining a synth.



//1. NN setup

(

    ~mlp = FluidMLPRegressor(s,[7],activation:FluidMLPRegressor.sigmoid,outputActivation:FluidMLPRegressor.sigmoid,maxIter: 1000,learnRate:0.1,batchSize:1,validation:0)


)


( //Execute each line independently
~inputdata = FluidDataSet(s);
~outputdata = FluidDataSet(s);
~inputbuf = Buffer.alloc(s,1,numChannels:1,bufnum:1);
~outputbuf = Buffer.alloc(s,2,numChannels:1,bufnum:2);
)

(

arg predicting=0;
~win = Window(name:"gui",bounds: Rect(1150,400,200,420)).front.alwaysOnTop_(true);


~butt1 = Button(~win, Rect(25, 20, width:150, height: 30));
~butt2 = Button(~win, Rect(25, 60, width:150, height: 30));
~butt3 = Button(~win, Rect(25, 100, width:150, height: 30));
~butt4 = Button(~win, Rect(25, 140, width:150, height: 30));
~butt5 = Button(~win, Rect(25, 180, width:150, height: 30));
~butt6 = Button(~win, Rect(25, 220, width:150, height: 30));
~butt7 = Button(~win, Rect(25, 260, width:150, height: 30));
~butt8 = Button(~win, Rect(25, 300, width:150, height: 30));
(
~butt1.states_([
	["Load Input data JSON file"],
	["Input data file loaded", Color.white, Color.green(0.7)]
]).action_{
	// x = FluidDataSet(s).load(~inputdata, action: {"Input data loaded".postln;}).print;
	FileDialog({
			arg folder;
		~inputdata.read("C:/Users/George Panicker/Desktop/chops/SC/neurosynth/Inputdata.json");
		},fileMode:0,acceptMode:0,stripResult:true);
	};

~butt2.states_([
	["Load Output data JSON file"],
	["Output data file loaded", Color.white, Color.green(0.7)]
]).action_{
		FileDialog({
			arg folder;
		~outputdata.read("C:/Users/George Panicker/Desktop/chops/SC/neurosynth/Outputdata.json");
		},fileMode:0,acceptMode:0,stripResult:true);
	};

~butt3.states_([
	["Normalize data"],
	["Data Normalized!", Color.white, Color.green(0.7)]
]).action_{
	arg butt;

	FluidNormalize(s).fitTransform(~inputdata,~inputdata);
    FluidNormalize(s).fitTransform(~outputdata,~outputdata);
	~inputdata.print;
	~outputdata.print;
	butt.value.postln;
	};

~butt4.states_([
	["Train", Color.black], ["Train", Color.grey(0.6)]
]).action_{
		~mlp.fit(~inputdata,~outputdata,action:{
			arg error;
			"the current error (aka. loss) is: %".format(error).postln;
		});
	};

~butt5.states_([
	["Save Trained Network", Color.black],
	["Training saved!", Color.white, Color.green(0.7)]
]).action_{
		Dialog.savePanel({
			arg path;
			if(PathName(path).extension != "json"){
				path = "%.json".format(path);
			};
			~mlp.write(path);
		});
	};

~butt6.states_([
	["Load NN (MLP file)"],
	["MLP loaded", Color.black, Color.gray(0.7)]
]).action_{
		Dialog.openPanel({
			arg path;
			~mlp.read(path);
		});
	};

~butt7.states_([
	["Predict", Color.black],
	["NN predicting", Color.black, Color.gray(0.7)]
]).action_{
		arg but;
	predicting = but.value.asBoolean;
	"'Now predicting values.'".postln;
};

~butt8.states_([
	["Play test Synth"],["Stop test synth", Color.red(0.7)]
]).action_{
arg button;
	if ( button.value == 1,
		{
			x = {
				arg amp =0.5 ;
	var sig1, sig2,mix,val, in;
	val = FluidBufToKr.kr(~outputbuf);
				sig1 = SinOsc.ar(if(predicting.value.asBoolean,val[0]*1000,400)); // this sinosc takes value from the first column

		Out.ar(0, sig1!2);
			}.play;
		},
	{x.free;}
	);
};
);

//Test sliders are meant to check if the NN
// is functional. The first slider should be able to
//move the second if it's reading from the outputbuf
//correctly
~slide1 = Slider(~win, Rect(25,345, width:150,height:40));


(
~slide1.action_{
	arg slide;
	~inputbuf.setn(0,[slide.value]);
	if(predicting){
		~mlp.predictPoint(~inputbuf,~outputbuf); // the mlp NN makes its predictions based on the values coming from the input buffer and then feeds it into the output buffer. This isthen taken from the synth
	};
};);



x.poll;


);




~outputbuf.poll;


//3. GUI removal
(
~butt1.remove;
~butt2.remove;
~butt3.remove;
~butt4.remove;
~butt5.remove;
~butt.remove;
~slide1.remove;
~win.close;
)

