append_to_file 'db/seeds.rb', <<-CODE
users = User.create [
  { email: 'liulantao@gmail.com', password: Devise.friendly_token[0, 20] },
  { email: 'liulantao@liulantao.com', password: Devise.friendly_token[0, 20] },
]

places = User.first.places.create [
  { name: '北京', description: '北京市，简称“京”，是中华人民共和国首都、直辖市和京津冀城市群的中心，中国的政治、文化、交通、科技创新和国际交往中心，经济、金融的决策与管理中心。' },
  { name: '上海', description: '上海市，简称沪，别称申，是中华人民共和国的一个直辖市，全国金融中心、交通枢纽。' },
  { name: '杭州', description: '杭州市简称杭，位于中华人民共和国东南沿海、浙江省北部，钱塘江下游北岸，京杭大运河南端。' },
  { name: '曼谷', description: '泰国首都' }
]

activities = User.first.activities.create [
  {
    description: '北京旅行',
    schedules: [
      Schedule.new(place: Place.find_by_name('北京'), start_date: Date.today - 15.days)
    ]
  },
  {
    description: '泰国旅行',
    schedules: [
      Schedule.new(place: Place.find_by_name('曼谷'), start_date: Date.today + 1.months, end_date: Date.today + 45.days)
    ]
  },
  {
    description: '江浙沪一周',
    schedules: [
      Schedule.new(place: Place.find_by_name('上海'), start_date: Date.today),
      Schedule.new(place: Place.find_by_name('杭州'), start_date: Date.tomorrow)
    ]
  },
]
CODE
