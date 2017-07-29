append_to_file 'db/seeds.rb', <<-CODE
users = User.create [
  { email: 'liulantao@gmail.com', password: Devise.friendly_token[0, 20] },
  { email: 'liulantao@liulantao.com', password: Devise.friendly_token[0, 20] },
]

places = User.first.places.create [
  { title: '北京', content: %q{北京市，简称“京”，是中华人民共和国首都、直辖市和京津冀城市群的中心，中国的政治、文化、交通、科技创新和国际交往中心，经济、金融的决策与管理中心。北京是世界上最大的城市之一，具有重要的国际影响力，人类发展指数位居中国大陆省级行政区第一位。 《不列颠百科全书》将北京形容为全球最伟大的城市之一，而且断言“这座城市是中国历史上最重要的组成部分。在中国过去的8个世纪里，几乎北京所有主要建筑都拥有着不可磨灭的民族和历史意义”。北京古迹众多，著名的有故宫、天坛、颐和园、圆明园、北海公园等。} },
  { title: '上海', content: %q{上海市，简称沪，别称申，是中华人民共和国的一个直辖市，全国金融中心、交通枢纽，其港口为世界集装箱吞吐量最多、货物吞吐吨位最大；主要产业包括商贸流通、金融、信息、制造等。上海位于中国东部弧形海岸线的正中间，长江三角洲最东部，东临东海，南濒杭州湾，西与江苏、浙江两省相接，北端的崇明岛处于长江入海口中。上海市是世界最大的城市之一，截至2016年，常住人口2419.70万，其中本地户籍人口占59%，达1439.50万；近年来，上海市也与周围的江苏、浙江两省高速发展的多个城市共同构成了长江三角洲城市群，是世界几大城市群之一。} },
  { title: '杭州', content: %q{杭州市简称杭，位于中华人民共和国东南沿海、浙江省北部，钱塘江下游北岸，京杭大运河南端。是浙江省省会，副省级城市之一，浙江省交通枢纽、长三角南翼的中心城市，浙江省的政治、经济、文化和金融中心，中国重要的电子商务中心，国际知名的旅游城市。 杭州的杭字本意是船，专指大禹治水乘坐过的船。杭州历史悠久，4700多年前就有人类在此繁衍生息；自秦朝设县治以来，已有2200多年历史。古时曾称“临安”（南宋）、“钱塘”、“武林”等。是吴越国和南宋的都城，为中国七大古都之一。市内有西湖、西溪湿地等景区，其中西湖周边还有文澜阁等众多名胜古迹。因为风景秀丽，自古有“人间天堂”的美誉。是全国重点风景旅游城市和首批历史文化名城。} },
  { title: '曼谷', content: %q{Bangkok (English: /ˈbæŋkɒk/) is the capital and most populous city of Thailand. It is known in Thai as Krung Thep Maha Nakhon (กรุงเทพมหานคร, pronounced [krūŋ tʰêːp mahǎː nákʰɔ̄ːn] (About this sound listen)) or simply Krung Thep. The city occupies 1,568.7 square kilometres (605.7 sq mi) in the Chao Phraya River delta in Central Thailand, and has a population of over 8 million, or 12.6 percent of the country's population. Over 14 million people (22.2 percent) live within the surrounding Bangkok Metropolitan Region, making Bangkok an extreme primate city, significantly dwarfing Thailand's other urban centres in terms of importance.} }
]

activities = User.first.activities.create [
  {
    title: '北京旅行',
    content: '北京旅行',
    schedules: [
      Schedule.new(place: Place.find_by_title('北京'), start_date: Date.today - 15.days)
    ]
  },
  {
    title: '泰国旅行',
    content: '泰国旅行',
    schedules: [
      Schedule.new(place: Place.find_by_title('曼谷'), start_date: Date.today + 1.months, end_date: Date.today + 45.days)
    ]
  },
  {
    title: '江浙沪一周',
    content: '江浙沪一周',
    schedules: [
      Schedule.new(place: Place.find_by_title('上海'), start_date: Date.today),
      Schedule.new(place: Place.find_by_title('杭州'), start_date: Date.tomorrow)
    ]
  },
]
CODE
