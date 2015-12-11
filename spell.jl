#!/usr/local/bin/julia
using Json2
using DataStructures:DefaultDict
typealias String AbstractString

words(text::String) = matchall(r"[a-z]+", lowercase(text))

function train(features)
	model = DefaultDict(1)
	for f in features
		model[f] += 1
	end
	model
end

NWORDS = train(words(readall(open("big.txt"))))

alphabet = "abcdefghijklmnopqrstuvwxyz"

function edits1(word::String)
	s = [(word[1:i], word[i+1:end]) for i in 0:length(word)]
	deletes    = Set(["$a$(b[2:end])" for (a, b) in filter(w->w[2]!="",s)])
	transposes = Set(["$a$(b[2])$(b[1])$(b[3:end])"	for (a, b) in filter(w->length(w[2])>1,s)])
	replaces   = Set(["$a$c$(b[2:end])"	for (a, b) in filter(w->w[2]!="",s), c in alphabet])
	inserts    = Set(["$a$c$b" for (a, b) in s, c in alphabet])
	union(deletes, transposes, replaces, inserts)
end

function known_edits2(word)
	ret = Set()
	for e1 in edits1(word)
		e2 = edits1(e1)
		union!(ret, filter(w->haskey(NWORDS, w), e2))
	end
	ret
end

known(words) = Set(filter(w->haskey(NWORDS, w), words))

function correct(word)
	maxFreq = 0
	maxWord = ""
	candidates = Set()

	w = known([word])
	if !isempty(w)
		candidates = w
	else
		w = known(edits1(word))
		if !isempty(w)
			candidates = w
		else
			w = known_edits2(word)
			if !isempty(w)
				candidates = w
			else
				return word
			end
		end
	end

	for	w in candidates
		if NWORDS[w] > maxFreq
			maxFreq = NWORDS[w]
			maxWord = w
		end
	end
	maxWord
end


#################### TEST 
function spelltest(tests, bias=Union{}, verbose=false)
	n, bad, unknown = 0, 0, 0
#if bias:
#for target in tests: NWORDS[target] += bias
	for target in getkeys(tests)
		wrongs = tests[target]
		for wrong in split(wrongs)
			n += 1
			w = correct(wrong)
			if w!=target
				bad += 1
				if !haskey(NWORDS, target)
					unknown += 1
				end
			end
		end
	end
	return Dict("bad"=>bad, "n"=>n, "bias"=>bias, "pct"=>floor(Int, 100. - 100.*bad/n),
				"unknown"=>unknown)
end

using Json2
#@time println(correct("xtas"))
#@time println(spelltest(Json2.parse(readall(open("test1.json","r")))))
@time println(spelltest(Json2.parse(readall(open("test2.json","r")))))
