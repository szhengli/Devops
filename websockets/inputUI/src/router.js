import VueRouter from 'vue-router'
import Vue from "vue"


import App from "./App.vue"

Vue.use(VueRouter)


const Foo = { template: '<div>james</div>' }
const Bar = { template: '<div>bar</div>' }

const routes= [

	  { path: '/main', component: App , name: 'Main'}
]


const router = new VueRouter({
	routes
})
router.beforeEach((to, from, next) => {

        next();
})

export default router;
