--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

-- Started on 2025-06-22 01:06:35

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 225 (class 1255 OID 16619)
-- Name: trg_addxp_after_correct_answer(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_addxp_after_correct_answer() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    correct_option CHAR(1);
BEGIN
    -- پیدا کردن گزینه صحیح از سوال مربوطه
    SELECT q.CorrectOption INTO correct_option
    FROM Rounds r
    JOIN Questions q ON r.QuestionID = q.QuestionID
    WHERE r.RoundID = NEW.RoundID;

    -- اگر پاسخ بازیکن درست بود، به XP او اضافه کن
    IF NEW.SelectedOption = correct_option THEN
        UPDATE PlayerStats
        SET XP = XP + 10
        WHERE UserID = NEW.UserID;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_addxp_after_correct_answer() OWNER TO postgres;

--
-- TOC entry 227 (class 1255 OID 16625)
-- Name: trg_limitquestionspercategory(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_limitquestionspercategory() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    question_count INT;
BEGIN
    SELECT COUNT(*) INTO question_count
    FROM Questions
    WHERE CategoryID = NEW.CategoryID;

    IF question_count >= 50 THEN
        RAISE EXCEPTION 'سقف تعداد سوالات این دسته پر شده است.';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_limitquestionspercategory() OWNER TO postgres;

--
-- TOC entry 228 (class 1255 OID 16627)
-- Name: trg_preventduplicateanswer(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_preventduplicateanswer() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM Answers
        WHERE RoundID = NEW.RoundID AND UserID = NEW.UserID
    ) THEN
        RAISE EXCEPTION 'شما قبلاً به این سوال پاسخ داده‌اید.';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_preventduplicateanswer() OWNER TO postgres;

--
-- TOC entry 226 (class 1255 OID 16623)
-- Name: trg_setregisterdate(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_setregisterdate() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.RegisterDate IS NULL THEN
        NEW.RegisterDate := CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_setregisterdate() OWNER TO postgres;

--
-- TOC entry 229 (class 1255 OID 16629)
-- Name: trg_updateaccuracy(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_updateaccuracy() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    total INT;
    correct INT;
    correct_option CHAR(1);
BEGIN
    -- گزینه صحیح را پیدا کن
    SELECT q.CorrectOption INTO correct_option
    FROM Rounds r
    JOIN Questions q ON r.QuestionID = q.QuestionID
    WHERE r.RoundID = NEW.RoundID;

    -- اگر پاسخ صحیح بود
    IF NEW.SelectedOption = correct_option THEN
        -- محاسبه تعداد کل پاسخ‌ها
        SELECT COUNT(*) INTO total
        FROM Answers
        WHERE UserID = NEW.UserID;

        -- محاسبه تعداد پاسخ‌های درست
        SELECT COUNT(*) INTO correct
        FROM Answers a
        JOIN Rounds r ON a.RoundID = r.RoundID
        JOIN Questions q ON r.QuestionID = q.QuestionID
        WHERE a.UserID = NEW.UserID AND a.SelectedOption = q.CorrectOption;

        -- بروزرسانی درصد دقت
        UPDATE PlayerStats
        SET Accuracy = (correct * 100.0) / total
        WHERE UserID = NEW.UserID;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_updateaccuracy() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 218 (class 1259 OID 16479)
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    categoryid integer NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16507)
-- Name: gamesessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gamesessions (
    sessionid integer NOT NULL,
    player1id integer NOT NULL,
    player2id integer NOT NULL,
    starttime time without time zone,
    endtime time without time zone,
    status character varying(10) DEFAULT 'active'::character varying,
    winnerid integer,
    CONSTRAINT gamesessions_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'completed'::character varying])::text[])))
);


ALTER TABLE public.gamesessions OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16560)
-- Name: playerstatus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.playerstatus (
    userid integer NOT NULL,
    totalgames integer DEFAULT 0,
    gameswon integer DEFAULT 0,
    gameslost integer DEFAULT 0,
    xp integer DEFAULT 0,
    accuracy integer
);


ALTER TABLE public.playerstatus OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16486)
-- Name: questions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.questions (
    questionid integer NOT NULL,
    text text NOT NULL,
    optiona character varying(255) NOT NULL,
    optionb character varying(255) NOT NULL,
    optionc character varying(255) NOT NULL,
    optiond character varying(255) NOT NULL,
    correctoption character(1) NOT NULL,
    difficultylevel character varying(10) NOT NULL,
    categoryid integer,
    authorid integer,
    status character varying(10),
    CONSTRAINT questions_correctoption_check CHECK ((correctoption = ANY (ARRAY['A'::bpchar, 'B'::bpchar, 'C'::bpchar, 'D'::bpchar]))),
    CONSTRAINT questions_difficultylevel_check CHECK (((difficultylevel)::text = ANY ((ARRAY['easy'::character varying, 'medium'::character varying, 'hard'::character varying])::text[]))),
    CONSTRAINT questions_status_check CHECK (((status)::text = ANY ((ARRAY['approved'::character varying, 'pending'::character varying, 'rejected'::character varying])::text[])))
);


ALTER TABLE public.questions OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16771)
-- Name: rounds; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rounds (
    roundid integer NOT NULL,
    sessionid integer NOT NULL,
    roundnumber integer NOT NULL,
    starttime timestamp without time zone NOT NULL,
    endtime timestamp without time zone NOT NULL
);


ALTER TABLE public.rounds OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16790)
-- Name: totaltable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.totaltable (
    userid integer NOT NULL,
    username character varying(50),
    xp integer,
    rank integer
);


ALTER TABLE public.totaltable OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16469)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    userid integer NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    passwordhash character varying(255) NOT NULL,
    registerdate date NOT NULL,
    status character varying(10) DEFAULT 'active'::character varying,
    CONSTRAINT users_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16846)
-- Name: weektable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.weektable (
    userid integer NOT NULL,
    username character varying(50),
    rank integer
);


ALTER TABLE public.weektable OWNER TO postgres;

--
-- TOC entry 4897 (class 0 OID 16479)
-- Dependencies: 218
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categories (categoryid, name) FROM stdin;
1	History
2	Movie
3	Music
4	Sport
5	Foods
6	Geography
\.


--
-- TOC entry 4899 (class 0 OID 16507)
-- Dependencies: 220
-- Data for Name: gamesessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gamesessions (sessionid, player1id, player2id, starttime, endtime, status, winnerid) FROM stdin;
1	5	2	23:20:08.977516	23:23:54.328161	completed	5
2	2	5	23:28:12.554155	23:29:50.435655	completed	\N
3	5	2	23:40:20.417976	23:40:54.40881	completed	2
4	2	3	00:21:20.787602	00:28:23.030179	completed	2
5	2	3	19:54:30.408322	\N	active	\N
6	2	3	20:01:04.841627	20:01:41.813395	completed	\N
7	2	3	20:07:36.672864	\N	active	\N
8	2	3	20:43:04.858892	20:43:35.155173	completed	2
9	2	3	20:44:22.658997	20:44:55.26985	completed	3
10	6	5	20:08:46.62363	20:09:21.82621	completed	6
11	2	5	20:05:10.994484	\N	active	\N
12	2	5	21:17:18.553185	21:17:50.953847	completed	2
13	2	5	21:19:10.60741	21:19:37.83708	completed	5
14	2	5	21:27:43.090088	21:28:11.608392	completed	5
15	7	2	21:29:41.769672	21:30:05.061726	completed	2
16	2	5	21:35:04.79002	21:35:27.829942	completed	5
17	2	7	\N	\N	active	\N
18	2	7	21:08:59.089172	\N	active	\N
19	2	5	21:09:36.376133	\N	active	\N
20	2	5	21:10:54.818613	\N	active	\N
21	2	5	21:11:32.632986	\N	active	\N
22	2	5	21:12:05.953231	21:12:39.119026	completed	2
23	2	5	21:13:33.449107	21:13:59.579264	completed	5
24	2	5	22:27:25.760886	\N	active	\N
25	5	2	22:27:51.330102	22:28:19.752437	completed	2
\.


--
-- TOC entry 4900 (class 0 OID 16560)
-- Dependencies: 221
-- Data for Name: playerstatus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playerstatus (userid, totalgames, gameswon, gameslost, xp, accuracy) FROM stdin;
3	3	1	1	-600	3
6	1	1	0	833	7
7	0	0	0	0	0
2	7	3	2	67	4
5	5	1	3	699	3
1	0	0	0	0	0
8	0	0	0	0	0
\.


--
-- TOC entry 4898 (class 0 OID 16486)
-- Dependencies: 219
-- Data for Name: questions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.questions (questionid, text, optiona, optionb, optionc, optiond, correctoption, difficultylevel, categoryid, authorid, status) FROM stdin;
183	in which year did the western roman empire fall?	410 ad	476 ad	395 ad	1453 ad	B	hard	1	1	approved
184	the battle of gaugamela was fought between which two empires?	persia and rome	persia and greece	egypt and ottoman	china and mongolia	B	hard	1	1	approved
185	who was the first female pharaoh of ancient egypt?	cleopatra	hatshepsut	nefertiti	tausret	B	hard	1	1	approved
186	which war ended with the "peace of westphalia"?	hundred years war	thirty years war	seven years war	world war i	B	hard	1	1	approved
187	the ming dynasty ruled which country?	japan	china	korea	vietnam	B	hard	1	1	approved
188	which country was the first to officially abolish slavery?	britain	france	portugal	denmark	D	hard	1	1	approved
189	the october revolution occurred in which year?	1914	1917	1921	1905	B	hard	1	1	approved
190	the treaty of versailles was signed after which war?	world war i	world war ii	franco-prussian war	crimean war	A	hard	1	1	approved
191	which of these was not part of the maya, aztec, and inca civilizations?	maya	aztec	inca	olmec	D	hard	1	1	approved
192	the han dynasty ruled which country?	japan	china	mongolia	india	B	hard	1	1	approved
193	the godfather is based on a novel by which author?	mario puzo	stephen king	j.d. salinger	ernest hemingway	A	hard	2	1	approved
194	who played the role of "johnny fontane" in the godfather?	al pacino	marlon brando	james caan	robert de niro	C	hard	2	1	approved
195	who directed the movie "blue velvet"?	david lynch	stanley kubrick	alfred hitchcock	quentin tarantino	A	hard	2	1	approved
196	which movie won the oscar for best picture in 1994?	schindler’s list	pulp fiction	forrest gump	the shawshank redemption	C	hard	2	1	approved
197	who directed "taxi driver"?	martin scorsese	francis ford coppola	brian de palma	miloš forman	A	hard	2	1	approved
198	who played "hannibal lecter" in the silence of the lambs?	anthony hopkins	jack nicholson	christoph waltz	ralph fiennes	A	hard	2	1	approved
199	how is the movie "memento" narrated?	linearly	reverse chronological order	parallel storylines	non-linear jumps	B	hard	2	1	approved
200	which film is not directed by quentin tarantino?	madame bovary’s buttons	the hateful eight	jackie brown	kill bill	A	hard	2	1	approved
201	the movie "the man who saved the earth" is about whom?	neil armstrong	stanley kubrick	john f. kennedy	wernher von braun	B	hard	2	1	approved
202	which movie won the palme d’or at cannes in 2019?	parasite	once upon a time in hollywood	pain and glory	the lighthouse	A	hard	2	1	approved
203	which band released the album "the dark side of the moon"?	led zeppelin	pink floyd	deep purple	the beatles	B	hard	3	1	approved
204	who performed the song "bohemian rhapsody"?	the rolling stones	queen	deep purple	ac/dc	B	hard	3	1	approved
205	which singer is known as the "king of pop"?	michael jackson	elvis presley	prince	madonna	A	hard	3	1	approved
206	the band "nirvana" was part of which music genre?	heavy metal	grunge	punk rock	disco	B	hard	3	1	approved
207	who wrote the song "like a rolling stone"?	bob dylan	elvis presley	john lennon	mick jagger	A	hard	3	1	approved
208	which michael jackson album is the best-selling of all time?	thriller	bad	off the wall	dangerous	A	hard	3	1	approved
209	the beatles originated from which city?	london	liverpool	manchester	birmingham	B	hard	3	1	approved
210	which guitarist is known as the "god of guitar"?	jimi hendrix	eric clapton	jimmy page	david gilmour	A	hard	3	1	approved
211	who wrote the song "imagine"?	john lennon	paul mccartney	bob dylan	elvis presley	A	hard	3	1	approved
212	which singer is known as the "queen of pop"?	madonna	whitney houston	mariah carey	lady gaga	A	hard	3	1	approved
213	which footballer has won the most ballon d’or awards?	lionel messi	cristiano ronaldo	michel platini	johan cruyff	A	hard	4	1	approved
214	which team has the most uefa champions league titles?	barcelona	bayern munich	real madrid	liverpool	C	hard	4	1	approved
215	which country won the most gold medals at the 2016 rio olympics?	usa	china	great britain	russia	A	hard	4	1	approved
216	which boxer is known as "the greatest"?	mike tyson	muhammad ali	floyd mayweather	manny pacquiao	B	hard	4	1	approved
217	which country has won the most fifa world cups?	germany	brazil	italy	argentina	B	hard	4	1	approved
218	which athlete is known as the "black pearl"?	pelé	diego maradona	usain bolt	muhammad ali	A	hard	4	1	approved
219	which tennis player has the most grand slam titles?	rafael nadal	roger federer	novak djokovic	pete sampras	C	hard	4	1	approved
220	who was the first woman to play in the nba?	lisa leslie	sheryl swoopes	ann meyers	nancy lieberman	D	hard	4	1	approved
221	which country will host the 2024 olympics?	tokyo	paris	los angeles	beijing	B	hard	4	1	approved
222	which boxer is nicknamed "rocky"?	sylvester stallone	muhammad ali	rocky marciano	mike tyson	C	hard	4	1	approved
223	which country is the origin of pasta?	italy	china	france	greece	B	hard	5	1	approved
224	which of these is not a french dish?	ratatouille	boeuf bourguignon	cassoulet	paella	D	hard	5	1	approved
225	what is béchamel sauce made of?	cream and butter	milk, flour, and butter	egg and oil	tomato and garlic	B	hard	5	1	approved
226	which dish originates from thailand?	pad thai	sushi	pizza	kebab	A	hard	5	1	approved
227	what is the key spice in "biryani"?	turmeric	saffron	red chili	cardamom	B	hard	5	1	approved
228	which country invented feta cheese?	italy	france	greece	switzerland	C	hard	5	1	approved
229	where does "kimchi" come from?	china	japan	south korea	vietnam	C	hard	5	1	approved
230	which drink is used in japanese tea ceremonies?	matcha	espresso	oolong	rooibos	A	hard	5	1	approved
231	which is not a mexican street food?	taco	tamale	pozole	pirozhki	D	hard	5	1	approved
232	parmigiano reggiano cheese comes from which country?	france	italy	switzerland	spain	B	hard	5	1	approved
233	what is the tallest waterfall in the world?	angel falls	niagara falls	victoria falls	iguazu falls	A	hard	6	1	approved
234	which country shares borders with the most nations?	russia	china	brazil	germany	B	hard	6	1	approved
235	what is the longest river in the world?	nile	amazon	yangtze	mississippi	A	hard	6	1	approved
236	what is the capital of australia?	sydney	melbourne	canberra	brisbane	C	hard	6	1	approved
237	which country is called the "land of a thousand lakes"?	norway	canada	finland	sweden	C	hard	6	1	approved
238	the strait of gibraltar separates which two continents?	europe and africa	asia and europe	america and asia	africa and asia	A	hard	6	1	approved
239	which ocean is the largest?	atlantic ocean	indian ocean	pacific ocean	arctic ocean	C	hard	6	1	approved
240	what is the tallest mountain outside asia?	mont blanc	aconcagua	kilimanjaro	mount elbrus	B	hard	6	1	approved
241	which country has the most islands?	indonesia	philippines	sweden	greece	C	hard	6	1	approved
242	how many countries does the danube river flow through?	4 countries	10 countries	15 countries	8 countries	B	hard	6	1	approved
283	which movie won the oscar for best picture in 2020?	parasite	1917	joker	star wars	A	hard	2	1	approved
1	who was the first president of the united states?	thomas jefferson	george washington	abraham lincoln	john adams	B	easy	1	1	approved
2	in which year did world war ii end?	1943	1945	1950	1939	B	easy	1	1	approved
3	who discovered america?	christopher columbus	leif erikson	vasco da gama	ferdinand magellan	A	easy	1	1	approved
4	which wall divided berlin during the cold war?	great wall	berlin wall	iron curtain	red wall	B	easy	1	1	approved
5	who was the british prime minister during world war ii?	winston churchill	neville chamberlain	tony blair	margaret thatcher	A	easy	1	1	approved
6	what was the name of the ship on which the pilgrims traveled to america?	mayflower	titanic	santa maria	beagle	A	easy	1	1	approved
7	which civilization built the pyramids?	greek	roman	egyptian	aztec	C	easy	1	1	approved
8	who was known as the maid of orleans?	cleopatra	joan of arc	queen victoria	elizabeth i	B	easy	1	1	approved
9	which war took place between 1914 and 1918?	world war i	world war ii	vietnam war	korean war	A	easy	1	1	approved
10	what empire did julius caesar belong to?	ottoman	roman	greek	persian	B	easy	1	1	approved
11	the industrial revolution began in which country?	france	germany	england	usa	C	medium	1	1	approved
12	who wrote "the communist manifesto"?	karl marx	vladimir lenin	friedrich engels	leon trotsky	A	medium	1	1	approved
13	when was the united nations founded?	1919	1945	1955	1939	B	medium	1	1	approved
14	who was the last czar of russia?	nicholas i	alexander iii	nicholas ii	ivan iv	C	medium	1	1	approved
15	which empire was ruled by genghis khan?	ottoman	mongol	roman	byzantine	B	medium	1	1	approved
16	in what year did the american civil war begin?	1776	1812	1861	1900	C	medium	1	1	approved
17	who was the first female prime minister of the uk?	theresa may	margaret thatcher	elizabeth ii	angela merkel	B	medium	1	1	approved
18	what triggered world war i?	bombing of hiroshima	sinking of lusitania	assassination of archduke franz ferdinand	attack on pearl harbor	C	medium	1	1	approved
19	who built the hanging gardens of babylon?	nebuchadnezzar ii	cyrus the great	alexander the great	hammurabi	A	medium	1	1	approved
20	which ancient city was buried by mount vesuvius?	rome	pompeii	athens	babylon	B	medium	1	1	approved
21	the treaty of versailles was signed in which year?	1917	1918	1919	1920	C	hard	1	1	approved
22	which ancient civilization built the machu picchu?	aztec	maya	inca	olmec	C	hard	1	1	approved
23	who was the first emperor of china?	liu bang	qin shi huang	kublai khan	sun yat-sen	B	hard	1	1	approved
24	which battle marked the end of napoleon’s rule?	waterloo	trafalgar	austerlitz	vienna	A	hard	1	1	approved
25	who was the founder of the achaemenid empire?	xerxes	darius	cyrus the great	artaxerxes	C	hard	1	1	approved
26	what was the code name for the normandy invasion?	operation overload	operation barbarossa	operation torch	operation market garden	A	hard	1	1	approved
27	who was the longest-reigning british monarch before queen elizabeth ii?	george iii	queen victoria	edward vii	elizabeth i	B	hard	1	1	approved
28	which medieval king signed the magna carta?	henry viii	edward i	john	richard i	C	hard	1	1	approved
29	the ottoman empire ended after which war?	balkan wars	crimean war	world war i	world war ii	C	hard	1	1	approved
30	who discovered the rosetta stone?	french soldiers	british archaeologists	napoleon	greek traders	A	hard	1	1	approved
31	who played the role of "jack" in titanic?	leonardo dicaprio	brad pitt	tom cruise	matt damon	A	easy	2	1	approved
32	which movie features the quote "may the force be with you"?	star trek	star wars	avatar	the matrix	B	easy	2	1	approved
33	who directed the "jurassic park" movie?	james cameron	peter jackson	steven spielberg	ridley scott	C	easy	2	1	approved
34	what is the name of the wizarding school in "harry potter"?	durmstrang	hogwarts	beauxbatons	hogsmeade	B	easy	2	1	approved
35	which actor played "iron man"?	chris evans	mark ruffalo	robert downey jr.	chris hemsworth	C	easy	2	1	approved
36	what kind of creature is shrek?	ogre	troll	giant	goblin	A	easy	2	1	approved
37	who voiced "buzz lightyear" in toy story?	tim allen	tom hanks	jim carrey	john goodman	A	easy	2	1	approved
38	in which movie does the character "tony montana" appear?	scarface	goodfellas	casino	the godfather	A	easy	2	1	approved
39	which film series is about a ring of power?	harry potter	the hobbit	lord of the rings	narnia	C	easy	2	1	approved
40	which disney movie features "hakuna matata"?	frozen	aladdin	the lion king	moana	C	easy	2	1	approved
41	who directed the movie "inception"?	steven spielberg	christopher nolan	quentin tarantino	martin scorsese	B	medium	2	1	approved
42	which actor played the joker in "the dark knight"?	jack nicholson	heath ledger	jared leto	joaquin phoenix	B	medium	2	1	approved
43	in which city is "la la land" set?	chicago	new york	los angeles	san francisco	C	medium	2	1	approved
44	what is the name of the killer in "scream"?	michael	freddy	ghostface	jason	C	medium	2	1	approved
45	which film won best picture in 2020?	joker	1917	parasite	once upon a time in hollywood	C	medium	2	1	approved
46	what is the name of the fictional african country in "black panther"?	zamunda	wakanda	genovia	latveria	B	medium	2	1	approved
47	who played forrest gump?	kevin spacey	brad pitt	tom hanks	john travolta	C	medium	2	1	approved
48	which actor appeared in both "the matrix" and "john wick"?	laurence fishburne	keanu reeves	hugo weaving	carrie-anne moss	B	medium	2	1	approved
49	in which movie does a character say "you can not handle the truth"?	a few good men	the firm	the pelican brief	jfk	A	medium	2	1	approved
50	what film features a character named tyler durden?	snatch	fight club	trainspotting	american psycho	B	medium	2	1	approved
51	which movie won the first academy award for best picture?	sunrise	wings	metropolis	all quiet on the western front	B	hard	2	1	approved
52	who directed the 1957 film "12 angry men"?	sidney lumet	alfred hitchcock	orson welles	elia kazan	A	hard	2	1	approved
53	which film had the highest box office before "avatar"?	titanic	the lord of the rings	harry potter	star wars	A	hard	2	1	approved
54	what is the name of the AI in "2001: a space odyssey"?	zen	hal 9000	sirius	vox	B	hard	2	1	approved
55	which italian director made "8½"?	fellini	rossellini	de sica	visconti	A	hard	2	1	approved
56	who composed the score for "the good, the bad and the ugly"?	john williams	ennio morricone	hans zimmer	howard shore	B	hard	2	1	approved
57	which actress starred in "roman holiday"?	marilyn monroe	audrey hepburn	grace kelly	vivien leigh	B	hard	2	1	approved
58	what film movement does "battleship potemkin" belong to?	german expressionism	french new wave	soviet montage	italian neorealism	C	hard	2	1	approved
59	who directed "rashomon"?	akira kurosawa	yasujiro ozu	takeshi kitano	hiroshi teshigahara	A	hard	2	1	approved
60	which film pioneered "bullet time" effects?	the matrix	blade	equilibrium	tron	A	hard	2	1	approved
61	who is known as the "king of pop"?	elvis presley	michael jackson	prince	madonna	B	easy	3	1	approved
62	which band sang "bohemian rhapsody"?	the beatles	queen	led zeppelin	pink floyd	B	easy	3	1	approved
63	who is the lead singer of u2?	freddie mercury	bono	mick jagger	sting	B	easy	3	1	approved
64	which artist is known for the song "shape of you"?	ed sheeran	justin bieber	shawn mendes	harry styles	A	easy	3	1	approved
65	what instrument does yo-yo ma play?	piano	violin	cello	flute	C	easy	3	1	approved
66	who is the lead singer of coldplay?	chris martin	adam levine	thom yorke	brandon flowers	A	easy	3	1	approved
67	which genre is taylor swift originally known for?	pop	rock	country	r&b	C	easy	3	1	approved
68	which rapper released the album "the marshall mathers lp"?	drake	eminem	kanye west	jay-z	B	easy	3	1	approved
69	who sang "imagine"?	john lennon	paul mccartney	george harrison	ringo starr	A	easy	3	1	approved
70	which group performed "hotel california"?	fleetwood mac	eagles	aerosmith	journey	B	easy	3	1	approved
71	what is the best-selling album of all time?	thriller	back in black	the dark side of the moon	rumours	A	medium	3	1	approved
72	which artist released the album "lemonade" in 2016?	beyoncé	rihanna	taylor swift	lady gaga	A	medium	3	1	approved
73	who composed the opera "the magic flute"?	beethoven	mozart	verdi	puccini	B	medium	3	1	approved
74	which band was kurt cobain a member of?	pearl jam	nirvana	soundgarden	alice in chains	B	medium	3	1	approved
75	which artist is known for "purple rain"?	prince	michael jackson	lenny kravitz	seal	A	medium	3	1	approved
76	which country is the band abba from?	germany	sweden	norway	denmark	B	medium	3	1	approved
77	what genre is miles davis associated with?	rock	blues	jazz	pop	C	medium	3	1	approved
78	who was the lead singer of the beatles?	john lennon	george harrison	paul mccartney	ringo starr	A	medium	3	1	approved
79	what is the real name of lady gaga?	stefani germanotta	katy hudson	roberta ciccone	alicia keys	A	medium	3	1	approved
80	which instrument is traditionally used in indian classical music?	violin	sitar	harp	banjo	B	medium	3	1	approved
81	who composed the "four seasons"?	wolfgang amadeus mozart	ludwig van beethoven	antonio vivaldi	johann sebastian bach	C	hard	3	1	approved
82	which musician was known as "the godfather of soul"?	james brown	ray charles	stevie wonder	marvin gaye	A	hard	3	1	approved
83	which minimalist composer created "music for 18 musicians"?	philip glass	john adams	steve reich	terry riley	C	hard	3	1	approved
84	who was the first woman inducted into the rock and roll hall of fame?	aretha franklin	madonna	tina turner	janis joplin	A	hard	3	1	approved
85	which composer became deaf later in life?	mozart	beethoven	bach	handel	B	hard	3	1	approved
86	what is the tempo marking "allegro" typically mean?	slow	very fast	moderately fast	lively and fast	D	hard	3	1	approved
87	which jazz musician was known for playing the saxophone in "kind of blue"?	miles davis	john coltrane	charlie parker	louis armstrong	B	hard	3	1	approved
88	which country originated the musical style flamenco?	france	portugal	spain	italy	C	hard	3	1	approved
89	which composer is known for the ballet "the rite of spring"?	stravinsky	rachmaninoff	debussy	tchaikovsky	A	hard	3	1	approved
90	what is a "libretto"?	a conductor’s baton	a small piano	an opera score	the text of an opera	D	hard	3	1	approved
91	which country won the fifa world cup in 2018?	germany	brazil	france	argentina	C	easy	4	1	approved
92	in which sport is the "stanley cup" awarded?	basketball	football	hockey	baseball	C	easy	4	1	approved
93	how many players are on a soccer team on the field?	9	10	11	12	C	easy	4	1	approved
94	which sport uses a racket and shuttlecock?	tennis	badminton	table tennis	squash	B	easy	4	1	approved
95	which country is known for sumo wrestling?	china	japan	korea	thailand	B	easy	4	1	approved
96	how many rings are there on the olympic flag?	3	4	5	6	C	easy	4	1	approved
97	which athlete is known as "the fastest man alive"?	carl lewis	usain bolt	tyson gay	michael johnson	B	easy	4	1	approved
98	which game is known as "the king of sports"?	basketball	cricket	football	tennis	C	easy	4	1	approved
99	which country invented cricket?	australia	england	india	south africa	B	easy	4	1	approved
100	how long is a marathon?	10 km	21.1 km	42.2 km	50 km	C	easy	4	1	approved
101	who has won the most tennis grand slam titles?	roger federer	rafael nadal	novak djokovic	pete sampras	C	medium	4	1	approved
102	which nba player is known as "the king"?	kobe bryant	lebron james	michael jordan	stephen curry	B	medium	4	1	approved
103	what year were the first modern olympic games held?	1892	1896	1900	1904	B	medium	4	1	approved
104	which country has won the most olympic medals?	china	usa	russia	germany	B	medium	4	1	approved
105	who won the fifa world cup in 2006?	italy	france	brazil	germany	A	medium	4	1	approved
106	what sport is associated with the davis cup?	cricket	tennis	golf	basketball	B	medium	4	1	approved
107	in which sport would you perform a slam dunk?	volleyball	basketball	wrestling	rugby	B	medium	4	1	approved
108	which city hosted the 2012 summer olympics?	beijing	rio de janeiro	london	tokyo	C	medium	4	1	approved
109	which golfer is known for wearing red on sundays?	phil mickelson	tiger woods	rory mcilroy	jack nicklaus	B	medium	4	1	approved
110	who holds the record for most home runs in a single mlb season?	barry bonds	babe ruth	mark mcgwire	alex rodriguez	A	medium	4	1	approved
111	who was the first athlete to run a sub-4-minute mile?	roger bannister	sebastian coe	usain bolt	carl lewis	A	hard	4	1	approved
112	which boxer retired with an undefeated record of 49-0?	muhammad ali	mike tyson	rocky marciano	floyd mayweather	C	hard	4	1	approved
113	which country has won the most rugby world cups?	south africa	new zealand	england	australia	B	hard	4	1	approved
114	which female gymnast has the most olympic medals?	nadia comaneci	simone biles	larisa latynina	mary lou retton	C	hard	4	1	approved
115	which footballer holds the record for most international goals?	pele	ronaldo	ali daei	cristiano ronaldo	D	hard	4	1	approved
116	which f1 driver won 7 world championships?	ayrton senna	lewis hamilton	michael schumacher	sebastian vettel	C	hard	4	1	approved
117	who is the only athlete to play in both a super bowl and a world series?	bo jackson	deion sanders	michael jordan	babe ruth	B	hard	4	1	approved
118	what is the name of the tennis player who won a golden slam in 1988?	serena williams	venus williams	martina navratilova	steffi graf	D	hard	4	1	approved
119	which country hosted the first fifa world cup?	brazil	italy	uruguay	argentina	C	hard	4	1	approved
120	which country won the cricket world cup in 2011?	australia	india	england	south africa	B	hard	4	1	approved
121	which country is pizza originally from?	usa	france	italy	spain	C	easy	5	1	approved
122	what is the main ingredient in guacamole?	tomato	avocado	onion	lime	B	easy	5	1	approved
123	sushi is a traditional dish from which country?	china	japan	thailand	korea	B	easy	5	1	approved
124	which fruit is yellow and curved?	apple	banana	pear	grape	B	easy	5	1	approved
125	what type of food is brie?	bread	cheese	meat	fruit	B	easy	5	1	approved
126	which beverage is made from fermented grapes?	vodka	beer	wine	cider	C	easy	5	1	approved
127	what is tofu made from?	rice	soybeans	milk	corn	B	easy	5	1	approved
128	which vegetable is known for making people cry when chopped?	carrot	onion	cabbage	pepper	B	easy	5	1	approved
129	what color is a ripe tomato?	green	yellow	red	purple	C	easy	5	1	approved
130	what is the main ingredient in hummus?	chickpeas	lentils	beans	peas	A	easy	5	1	approved
131	what is the national dish of spain?	paella	tapas	gazpacho	churros	A	medium	5	1	approved
132	which cheese is used in traditional greek salad?	cheddar	feta	mozzarella	parmesan	B	medium	5	1	approved
133	which pasta shape is long and thin?	penne	macaroni	spaghetti	farfalle	C	medium	5	1	approved
134	which country is famous for croissants?	spain	italy	france	germany	C	medium	5	1	approved
135	kimchi is a traditional dish from which country?	china	japan	vietnam	south korea	D	medium	5	1	approved
136	what is the main ingredient of black pudding?	rice	blood	flour	milk	B	medium	5	1	approved
137	which nut is used to make marzipan?	peanut	almond	cashew	hazelnut	B	medium	5	1	approved
138	what is the main alcoholic ingredient in a margarita?	vodka	rum	tequila	whiskey	C	medium	5	1	approved
139	from which animal does prosciutto come?	cow	pig	goat	deer	B	medium	5	1	approved
140	which spice is obtained from the crocus flower?	saffron	turmeric	cinnamon	cardamom	A	medium	5	1	approved
141	what is the key spice in indian biryani?	turmeric	cumin	saffron	coriander	C	hard	5	1	approved
142	which country invented the dish "beef wellington"?	france	england	usa	germany	B	hard	5	1	approved
143	what is surströmming?	cheese	fermented fish	pickled cabbage	spicy sausage	B	hard	5	1	approved
144	which italian cheese is traditionally made from buffalo milk?	parmesan	gorgonzola	ricotta	mozzarella	D	hard	5	1	approved
145	what type of pastry is used in a baklava?	puff pastry	phyllo dough	shortcrust pastry	choux pastry	B	hard	5	1	approved
146	which dish uses arborio rice?	paella	pilaf	risotto	biryani	C	hard	5	1	approved
147	which fruit has seeds on the outside?	blueberry	strawberry	raspberry	grape	B	hard	5	1	approved
148	what is tempeh made from?	soybeans	lentils	wheat	tofu	A	hard	5	1	approved
149	which fungus is a culinary delicacy and can be very expensive?	shiitake	button mushroom	porcini	truffle	D	hard	5	1	approved
150	which scandinavian dish is made of dried and salted cod?	lutefisk	gravlax	fiskeboller	rakfisk	A	hard	5	1	approved
151	what is the capital of france?	berlin	madrid	paris	rome	C	easy	6	1	approved
152	which is the largest ocean?	atlantic	indian	pacific	arctic	C	easy	6	1	approved
153	mount everest is located on the border of which two countries?	china and india	nepal and china	nepal and india	china and bhutan	B	easy	6	1	approved
154	what is the capital of japan?	beijing	tokyo	seoul	osaka	B	easy	6	1	approved
155	which continent is egypt in?	asia	africa	europe	australia	B	easy	6	1	approved
156	what is the capital city of australia?	sydney	melbourne	perth	canberra	D	easy	6	1	approved
157	which country is known as the land of the rising sun?	china	thailand	japan	vietnam	C	easy	6	1	approved
158	which river runs through london?	seine	danube	thames	rhine	C	easy	6	1	approved
159	how many continents are there?	5	6	7	8	C	easy	6	1	approved
160	which country is shaped like a boot?	spain	italy	greece	portugal	B	easy	6	1	approved
161	which river flows through rome?	tiber	seine	danube	thames	A	medium	6	1	approved
162	mount everest is located in which mountain range?	andes	himalayas	alps	rockies	B	medium	6	1	approved
163	which desert is the largest in the world?	gobi	sahara	arabian	kalahari	B	medium	6	1	approved
164	which city is also known as the "big apple"?	los angeles	new york	chicago	boston	B	medium	6	1	approved
165	which country has the longest coastline?	canada	australia	russia	usa	A	medium	6	1	approved
166	which line divides the earth into northern and southern hemispheres?	tropic of cancer	tropic of capricorn	prime meridian	equator	D	medium	6	1	approved
167	which african country has the most population?	egypt	ethiopia	nigeria	south africa	C	medium	6	1	approved
168	what is the capital of canada?	toronto	vancouver	ottawa	montreal	C	medium	6	1	approved
169	which river is the longest in the world?	amazon	nile	yangtze	mississippi	B	medium	6	1	approved
170	which is the smallest country in the world?	monaco	malta	vatican city	andorra	C	medium	6	1	approved
171	which country has the most time zones?	usa	russia	china	france	D	hard	6	1	approved
172	what is the driest desert in the world?	sahara	atacama	gobi	kalahari	B	hard	6	1	approved
173	what is the capital of mongolia?	ulaanbaatar	astana	tashkent	bishkek	A	hard	6	1	approved
174	which country is home to the most volcanoes?	japan	indonesia	iceland	philippines	B	hard	6	1	approved
175	which island is the largest in the world?	greenland	new guinea	borneo	madagascar	A	hard	6	1	approved
176	which sea has the highest salinity?	red sea	dead sea	arabian sea	caspian sea	B	hard	6	1	approved
177	which country is both in europe and asia?	greece	armenia	turkey	azerbaijan	C	hard	6	1	approved
178	which city is the southernmost capital in the world?	santiago	wellington	canberra	cape town	B	hard	6	1	approved
179	which lake is the deepest in the world?	lake superior	lake tanganyika	lake baikal	lake victoria	C	hard	6	1	approved
180	which mountain is the highest outside asia?	denali	kilimanjaro	aconcagua	elbrus	C	hard	6	1	approved
181	which planet is known as the "red planet"?	venus	mars	jupiter	saturn	B	easy	6	1	approved
182	who painted the mona lisa?	pablo picasso	vincent van gogh	leonardo da vinci	michelangelo	C	easy	2	1	approved
\.


--
-- TOC entry 4901 (class 0 OID 16771)
-- Dependencies: 222
-- Data for Name: rounds; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rounds (roundid, sessionid, roundnumber, starttime, endtime) FROM stdin;
11	1	1	2025-06-16 23:20:13.577292	2025-06-16 23:21:23.214791
12	1	2	2025-06-16 23:22:06.476436	2025-06-16 23:22:30.524505
13	1	3	2025-06-16 23:22:55.955767	2025-06-16 23:23:17.84045
14	1	4	2025-06-16 23:23:25.236831	2025-06-16 23:23:35.478437
15	1	5	2025-06-16 23:23:47.227756	2025-06-16 23:23:54.261066
21	2	1	2025-06-16 23:28:17.148732	2025-06-16 23:28:26.41467
22	2	2	2025-06-16 23:28:32.122902	2025-06-16 23:28:38.416067
23	2	3	2025-06-16 23:28:43.150988	2025-06-16 23:28:51.205521
24	2	4	2025-06-16 23:29:10.667445	2025-06-16 23:29:31.082624
25	2	5	2025-06-16 23:29:35.9773	2025-06-16 23:29:50.434856
31	3	1	2025-06-16 23:40:24.451431	2025-06-16 23:40:28.2466
32	3	2	2025-06-16 23:40:30.977899	2025-06-16 23:40:35.157138
33	3	3	2025-06-16 23:40:37.804433	2025-06-16 23:40:41.230824
34	3	4	2025-06-16 23:40:43.552889	2025-06-16 23:40:47.241751
35	3	5	2025-06-16 23:40:50.518411	2025-06-16 23:40:54.407678
41	4	1	2025-06-17 00:21:27.180903	2025-06-17 00:22:21.539685
42	4	2	2025-06-17 00:22:30.351571	2025-06-17 00:23:25.078262
43	4	3	2025-06-17 00:23:32.691344	2025-06-17 00:24:17.090144
44	4	4	2025-06-17 00:28:11.933798	2025-06-17 00:28:15.47917
45	4	5	2025-06-17 00:28:19.037343	2025-06-17 00:28:22.956599
61	6	1	2025-06-17 20:01:08.303619	2025-06-17 20:01:19.459547
62	6	2	2025-06-17 20:01:22.495677	2025-06-17 20:01:25.519056
63	6	3	2025-06-17 20:01:27.701743	2025-06-17 20:01:30.526834
64	6	4	2025-06-17 20:01:32.874176	2025-06-17 20:01:35.789002
65	6	5	2025-06-17 20:01:38.781634	2025-06-17 20:01:41.812314
71	7	1	2025-06-17 20:07:41.181506	2025-06-17 20:07:44.22816
72	7	2	2025-06-17 20:07:46.688101	2025-06-17 20:07:49.239535
81	8	1	2025-06-17 20:43:09.22339	2025-06-17 20:43:12.596649
82	8	2	2025-06-17 20:43:14.717621	2025-06-17 20:43:17.962814
83	8	3	2025-06-17 20:43:20.235467	2025-06-17 20:43:23.827571
84	8	4	2025-06-17 20:43:26.325762	2025-06-17 20:43:29.585787
85	8	5	2025-06-17 20:43:31.775786	2025-06-17 20:43:35.08806
91	9	1	2025-06-17 20:44:24.9561	2025-06-17 20:44:28.084371
92	9	2	2025-06-17 20:44:29.737894	2025-06-17 20:44:32.521437
93	9	3	2025-06-17 20:44:34.359125	2025-06-17 20:44:37.343552
94	9	4	2025-06-17 20:44:39.244014	2025-06-17 20:44:49.812262
95	9	5	2025-06-17 20:44:52.362297	2025-06-17 20:44:55.205305
101	10	1	2025-06-18 20:08:49.282771	2025-06-18 20:08:53.700979
102	10	2	2025-06-18 20:08:55.784876	2025-06-18 20:08:59.044533
103	10	3	2025-06-18 20:09:02.532105	2025-06-18 20:09:06.207171
104	10	4	2025-06-18 20:09:08.718571	2025-06-18 20:09:12.353883
105	10	5	2025-06-18 20:09:18.393215	2025-06-18 20:09:21.825103
111	11	1	2025-06-21 20:05:15.289998	2025-06-21 20:05:19.124637
112	11	2	2025-06-21 20:05:21.899065	2025-06-21 20:05:25.426688
121	12	1	2025-06-21 21:17:24.007931	2025-06-21 21:17:28.284074
122	12	2	2025-06-21 21:17:31.398698	2025-06-21 21:17:34.580063
123	12	3	2025-06-21 21:17:36.580221	2025-06-21 21:17:39.729009
124	12	4	2025-06-21 21:17:41.785795	2025-06-21 21:17:45.359634
125	12	5	2025-06-21 21:17:47.322203	2025-06-21 21:17:50.953256
131	13	1	2025-06-21 21:19:12.936896	2025-06-21 21:19:17.021816
132	13	2	2025-06-21 21:19:18.445807	2025-06-21 21:19:22.598871
133	13	3	2025-06-21 21:19:24.084234	2025-06-21 21:19:27.61201
134	13	4	2025-06-21 21:19:29.405501	2025-06-21 21:19:32.540612
135	13	5	2025-06-21 21:19:34.591747	2025-06-21 21:19:37.826254
141	14	1	2025-06-21 21:27:45.274217	2025-06-21 21:27:47.835774
142	14	2	2025-06-21 21:27:51.830271	2025-06-21 21:27:54.247786
143	14	3	2025-06-21 21:27:58.079592	2025-06-21 21:28:00.504625
144	14	4	2025-06-21 21:28:02.264508	2025-06-21 21:28:05.100874
145	14	5	2025-06-21 21:28:08.430422	2025-06-21 21:28:11.607562
151	15	1	2025-06-21 21:29:43.802629	2025-06-21 21:29:46.973438
152	15	2	2025-06-21 21:29:48.898085	2025-06-21 21:29:51.613919
153	15	3	2025-06-21 21:29:53.370589	2025-06-21 21:29:56.976462
154	15	4	2025-06-21 21:29:58.239318	2025-06-21 21:30:00.820421
155	15	5	2025-06-21 21:30:02.521212	2025-06-21 21:30:05.04327
161	16	1	2025-06-21 21:35:06.732158	2025-06-21 21:35:09.526711
162	16	2	2025-06-21 21:35:11.963034	2025-06-21 21:35:14.388235
163	16	3	2025-06-21 21:35:16.188357	2025-06-21 21:35:18.791848
164	16	4	2025-06-21 21:35:20.802148	2025-06-21 21:35:23.149251
165	16	5	2025-06-21 21:35:24.834564	2025-06-21 21:35:27.764995
171	17	1	2025-06-21 22:04:11.21187	2025-06-21 22:04:14.108494
172	17	2	2025-06-21 22:04:16.591192	2025-06-21 22:04:19.195567
173	17	3	2025-06-21 22:04:20.733167	2025-06-21 22:04:24.193819
174	17	4	2025-06-21 22:04:25.517275	2025-06-21 22:04:29.625174
175	17	5	2025-06-21 22:04:31.175201	2025-06-21 22:04:33.596958
211	21	1	2025-06-21 21:11:34.608759	2025-06-21 21:11:38.009648
221	22	1	2025-06-21 21:12:08.261377	2025-06-21 21:12:11.78606
222	22	2	2025-06-21 21:12:15.031319	2025-06-21 21:12:18.536593
223	22	3	2025-06-21 21:12:21.757857	2025-06-21 21:12:25.457606
224	22	4	2025-06-21 21:12:29.134354	2025-06-21 21:12:32.932902
225	22	5	2025-06-21 21:12:35.764472	2025-06-21 21:12:39.117956
231	23	1	2025-06-21 21:13:35.552724	2025-06-21 21:13:38.43316
232	23	2	2025-06-21 21:13:40.701977	2025-06-21 21:13:43.638533
233	23	3	2025-06-21 21:13:45.861642	2025-06-21 21:13:48.96568
234	23	4	2025-06-21 21:13:51.309459	2025-06-21 21:13:54.427031
235	23	5	2025-06-21 21:13:56.673806	2025-06-21 21:13:59.57809
241	24	1	2025-06-21 22:27:27.929231	2025-06-21 22:27:30.601198
251	25	1	2025-06-21 22:27:53.465403	2025-06-21 22:27:55.81361
252	25	2	2025-06-21 22:27:59.279873	2025-06-21 22:28:02.293841
253	25	3	2025-06-21 22:28:06.015489	2025-06-21 22:28:09.856525
254	25	4	2025-06-21 22:28:11.578032	2025-06-21 22:28:14.370831
255	25	5	2025-06-21 22:28:16.373029	2025-06-21 22:28:19.751386
\.


--
-- TOC entry 4902 (class 0 OID 16790)
-- Dependencies: 223
-- Data for Name: totaltable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.totaltable (userid, username, xp, rank) FROM stdin;
5	adnan	899	1
6	mohammad	833	2
7	zharfa	0	3
2	rosiiiw	0	3
3	iliya	-600	5
\.


--
-- TOC entry 4896 (class 0 OID 16469)
-- Dependencies: 217
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (userid, username, email, passwordhash, registerdate, status) FROM stdin;
7	zharfa	zharfa@gmail.com	$2b$12$wABF1yDFDKBxe9rviZ7tbOxjotb3suKJ4/tvY3VF4D6wVQi85gm9K	2025-06-21	active
1	rose	rose@gmail.com	$2b$12$UpqosgXMa98gglFnWSsAUeP2QNIS1poyLnOfHDHDlf9CoKAVOEl5q	2025-06-21	active
8	sarina	sarina@gmail.com	$2b$12$4Re1ILEJUfwe35RFpIkUIOUo4W1pgdkzUH4nQe65IS0dS2F2BDZS2	2025-06-22	active
5	adnan	adnan@gmail.com	$2b$12$YhkzLPY74/V8bg5q6TC/tuc.lQYrhtCX9k.aEHZrb.sEJf5qTG14i	2025-06-16	inactive
2	rosiiiw	roseiiiw@gmail.com	$2b$12$N4MrEhNT4GysN6vgTuQvR.kN4WVHsX6zlBxZIIS.0UXZHeZrvmKlq	2025-06-16	active
3	iliya	iliya@gmail.com	$2b$12$HVO8V8WXnQn6GINEDFQW/efU5vu.IhbnKhn00VOpNtbwRRN9PZL5W	2025-06-16	active
6	mohammad	mohammad@gmail.com	$2b$12$JBSWwUdjW58DgCaHV641VuOYQOQgjSbmAaEWTE3Z2LPF0/RVbq7QO	2025-06-18	active
\.


--
-- TOC entry 4903 (class 0 OID 16846)
-- Dependencies: 224
-- Data for Name: weektable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.weektable (userid, username, rank) FROM stdin;
2	rosiiiw	1
5	adnan	2
6	mohammad	3
3	iliya	4
\.


--
-- TOC entry 4722 (class 2606 OID 16485)
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- TOC entry 4724 (class 2606 OID 16483)
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (categoryid);


--
-- TOC entry 4730 (class 2606 OID 16513)
-- Name: gamesessions gamesessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gamesessions
    ADD CONSTRAINT gamesessions_pkey PRIMARY KEY (sessionid);


--
-- TOC entry 4733 (class 2606 OID 16569)
-- Name: playerstatus playerstats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playerstatus
    ADD CONSTRAINT playerstats_pkey PRIMARY KEY (userid);


--
-- TOC entry 4728 (class 2606 OID 16496)
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (questionid);


--
-- TOC entry 4735 (class 2606 OID 16775)
-- Name: rounds rounds_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rounds
    ADD CONSTRAINT rounds_pkey PRIMARY KEY (roundid);


--
-- TOC entry 4737 (class 2606 OID 16794)
-- Name: totaltable totaltable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.totaltable
    ADD CONSTRAINT totaltable_pkey PRIMARY KEY (userid);


--
-- TOC entry 4716 (class 2606 OID 16478)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 4718 (class 2606 OID 16474)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (userid);


--
-- TOC entry 4720 (class 2606 OID 16476)
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 4739 (class 2606 OID 16850)
-- Name: weektable weektable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weektable
    ADD CONSTRAINT weektable_pkey PRIMARY KEY (userid);


--
-- TOC entry 4725 (class 1259 OID 16615)
-- Name: idx_category_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_category_name ON public.categories USING btree (name);


--
-- TOC entry 4713 (class 1259 OID 16614)
-- Name: idx_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_email ON public.users USING btree (email);


--
-- TOC entry 4731 (class 1259 OID 16617)
-- Name: idx_game_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_game_status ON public.gamesessions USING btree (status);


--
-- TOC entry 4714 (class 1259 OID 16618)
-- Name: idx_passwordhash; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_passwordhash ON public.users USING btree (passwordhash);


--
-- TOC entry 4726 (class 1259 OID 16616)
-- Name: idx_question_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_question_category ON public.questions USING btree (categoryid);


--
-- TOC entry 4750 (class 2620 OID 16626)
-- Name: questions trg_limitquestionspercategory; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_limitquestionspercategory BEFORE INSERT ON public.questions FOR EACH ROW EXECUTE FUNCTION public.trg_limitquestionspercategory();


--
-- TOC entry 4749 (class 2620 OID 16624)
-- Name: users trg_setregisterdate; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_setregisterdate BEFORE INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.trg_setregisterdate();


--
-- TOC entry 4742 (class 2606 OID 16514)
-- Name: gamesessions gamesessions_player1id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gamesessions
    ADD CONSTRAINT gamesessions_player1id_fkey FOREIGN KEY (player1id) REFERENCES public.users(userid);


--
-- TOC entry 4743 (class 2606 OID 16519)
-- Name: gamesessions gamesessions_player2id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gamesessions
    ADD CONSTRAINT gamesessions_player2id_fkey FOREIGN KEY (player2id) REFERENCES public.users(userid);


--
-- TOC entry 4744 (class 2606 OID 16524)
-- Name: gamesessions gamesessions_winnerid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gamesessions
    ADD CONSTRAINT gamesessions_winnerid_fkey FOREIGN KEY (winnerid) REFERENCES public.users(userid);


--
-- TOC entry 4745 (class 2606 OID 16925)
-- Name: playerstatus playerstats_userid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playerstatus
    ADD CONSTRAINT playerstats_userid_fkey FOREIGN KEY (userid) REFERENCES public.users(userid) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4740 (class 2606 OID 16502)
-- Name: questions questions_authorid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_authorid_fkey FOREIGN KEY (authorid) REFERENCES public.users(userid);


--
-- TOC entry 4741 (class 2606 OID 16497)
-- Name: questions questions_categoryid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_categoryid_fkey FOREIGN KEY (categoryid) REFERENCES public.categories(categoryid);


--
-- TOC entry 4746 (class 2606 OID 16776)
-- Name: rounds rounds_sessionid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rounds
    ADD CONSTRAINT rounds_sessionid_fkey FOREIGN KEY (sessionid) REFERENCES public.gamesessions(sessionid);


--
-- TOC entry 4747 (class 2606 OID 16795)
-- Name: totaltable userid; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.totaltable
    ADD CONSTRAINT userid FOREIGN KEY (userid) REFERENCES public.playerstatus(userid);


--
-- TOC entry 4748 (class 2606 OID 16851)
-- Name: weektable weektable_userid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weektable
    ADD CONSTRAINT weektable_userid_fkey FOREIGN KEY (userid) REFERENCES public.users(userid);


-- Completed on 2025-06-22 01:06:35

--
-- PostgreSQL database dump complete
--

