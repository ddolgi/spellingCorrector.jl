#!/usr/local/bin/julia
using DataStructures:DefaultDict

words(text) = collect(e.match for e in eachmatch(r"[a-z]+", lowercase(text)))

function train(features)
	model = DefaultDict(1)
	for f in features
		model[f] += 1
	end
	model
end

NWORDS = train(words(String(read(open("big.txt")))))

alphabet = "abcdefghijklmnopqrstuvwxyz"

function edits1(word)
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
	(w = known([word])) != Set() || (w = known(edits1(word))) != Set() || (w = known_edits2(word)) != Set() || (w = [word])
	candidates = [ c for c in w ]
	candidates[findmax([ NWORDS[c] for c in candidates ])[2]]
end


#################### TEST 
function spelltest(tests, bias=Union{}, verbose=false)
	n, bad, unknown = 0, 0, 0
#if bias:
#for target in tests: NWORDS[target] += bias
	for (target, wrongs) in tests
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
	return Dict("bad"=>bad, "n"=>n, "bias"=>bias, "pct"=>floor(Int, 100.0 - 100.0*bad/n),
				"unknown"=>unknown)
end

using JSON
@time println(correct("xtas"))
# @time println(spelltest(JSON.parse(open("test1.json","r"))))
@time println(spelltest(JSON.parse(open("test2.json","r"))))
